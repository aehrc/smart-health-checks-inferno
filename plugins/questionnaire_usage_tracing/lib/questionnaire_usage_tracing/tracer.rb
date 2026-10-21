# frozen_string_literal: true

require_relative 'ast'
require_relative 'log'
require_relative 'profile_matcher'
require_relative 'query_search'

module InfernoSuitePlugins
  module QuestionnaireUsageTracing
    # Finds the questionnaire sources that link to each profile in the suite and
    # the items that use them.
    #
    # `trace` returns `{ profile_url => [trace entries] }`. Every `Questionnaire`
    # in `ig_resources` is traced.
    class Tracer
      ASSEMBLE_CONTEXT_URL = 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-assembleContext'

      def initialize(ig_resources, groups)
        @ig_resources = ig_resources
        @matcher = ProfileMatcher.new(groups, ig_resources)
      end

      def trace
        traces = {}
        @ig_resources.get_resources_by_type('Questionnaire').each do |questionnaire|
          trace_form(traces, questionnaire.to_hash)
        end
        traces
      end

      private

      def trace_form(traces, questionnaire)
        form = Form.new(questionnaire)
        log_assemble_contexts(form, questionnaire)
        form.query_variables.each { |variable| trace_query(traces, Query.new(form, variable, @ig_resources)) }
        form.launch_contexts.each { |launch_context| add_launch_context(traces, form, launch_context) }
        form.template_extracts.each { |extract| add_template(traces, Template.new(form, extract)) }
      end

      # A module form gets its `assembleContext` variables from the form it is
      # assembled into, so their usages are traced in the assembled form only.
      def log_assemble_contexts(form, questionnaire)
        names = Array(questionnaire['extension']).filter_map do |extension|
          extension['valueString'] if extension['url'] == ASSEMBLE_CONTEXT_URL
        end
        return if names.empty?

        names &= references(form, questionnaire)
        return if names.empty?

        QuestionnaireUsageTracing.log("#{form.label} reads #{names.join(', ')} from the form it is assembled " \
                                      'into: trace the assembled form for their usages')
      end

      # The `%Name` names the expressions on the root and on items reference.
      def references(form, questionnaire)
        expressions = form.scope(questionnaire).flat_map { |owner| form.expressions(owner) }
        expressions.flat_map { |expression| form.fhirpath.references(expression[:expression]) }
      end

      # A `query` entry for the query's own type and an `include` entry for each
      # `_include` target type. Chains are routed by type: one that picks an
      # included type, with `entry.resource.ofType(T)` or
      # `entry.where(resource is T)`, goes to that include entry, anything else
      # to the query entry.
      #
      # An included resource of the query's own type can't be told apart from
      # the query's own resources by type, so chains of that type stay with the
      # query entry, and its include entry has no usages.
      def trace_query(traces, query)
        add_query(traces, query)
        query.includes.each { |include| add_include(traces, query, include) }
      end

      # A read, like `Patient/{{%patient.id}}`, has no codes to tell profiles
      # apart, so it links to every group of its type, like a launch context.
      def add_query(traces, query)
        result = @matcher.match(query.resource_type, codes: query.codes, any_of_type: query.read?,
                                                     context: query.label)
        return unless result

        used_in, elements_read = query.usages { |type| !query.other_include_types.include?(type) }
        add(traces, result, query.entry('query', matched_by: result[:matched_by], elements_read:, used_in:))
      end

      def add_include(traces, query, include)
        target = include[:target]
        result = @matcher.match(target, any_of_type: true, context: "#{query.label} include #{include[:value]}")
        return unless result

        used_in, elements_read = target == query.resource_type ? [[], []] : query.usages { |type| type == target }
        add(traces, result, query.entry('include', include: include[:value], target_by: include[:target_by],
                                                   matched_by: result[:matched_by], elements_read:, used_in:))
      end

      # One entry per type of the launch context that has groups. `%name` is
      # the resource itself, not a Bundle. A chain that picks one type, like
      # `%user.where(resourceType = 'PractitionerRole')`, counts for that
      # type only.
      def add_launch_context(traces, form, launch_context)
        name = launch_context[:name]
        source = { name:, owner: launch_context[:owner], bundle: false }
        launch_context[:types].each do |type|
          result = @matcher.match(type, any_of_type: true, context: "#{form.label} launch context #{name}")
          next unless result

          accept = ->(chain_type) { chain_type.nil? || chain_type == type }
          used_in, elements_read = Usages.new(form, source, accept).call
          add(traces, result, { source: 'launch_context', **form.header, name:, defined_at: launch_context[:defined_at],
                                matched_by: result[:matched_by], elements_read:, used_in: })
        end
      end

      def add_template(traces, template)
        unless template.found?
          return QuestionnaireUsageTracing.log("skipping #{template.label}: no contained resource " \
                                               "#{template.reference}")
        end

        result = @matcher.match(template.resource_type, codes: template.codes, context: template.label)
        add(traces, result, template.entry(result[:matched_by])) if result
      end

      def add(traces, result, entry)
        result[:groups].each { |group| (traces[group.profile_url] ||= []) << entry }
      end

      # One x-fhir-query variable of a form, with its `_include` targets.
      class Query
        attr_reader :resource_type, :codes

        def initialize(form, variable, ig_resources)
          @form = form
          @variable = variable
          @ig_resources = ig_resources
          input = ProfileMatcher.from_query(variable[:expression])
          @resource_type = input[:resource_type]
          @codes = input[:codes]
          @read = input[:read]
        end

        def label
          "#{@form.label} query #{@variable[:name]}"
        end

        # Whether the query reads one resource by id, so `%Name` is that
        # resource instead of a Bundle.
        def read?
          @read
        end

        # `[used_in, elements_read]` for the chains whose type the block takes.
        def usages(&accept)
          source = { name: @variable[:name], owner: @variable[:owner], bundle: !read? }
          Usages.new(@form, source, accept).call
        end

        # A trace entry: the fields shared by `query` and `include` entries,
        # then `fields`. `read: true` marks a read.
        def entry(source, **fields)
          { source:, **@form.header, name: @variable[:name], defined_at: @variable[:defined_at],
            query: @variable[:expression], **(read? ? { read: true } : {}), **fields }
        end

        # `{ value:, target:, target_by: }` for each target type of each
        # `_include` of the query's own type. The target is the explicit
        # `Source:param:Target`, else the SearchParameter's `target` list, else
        # the types the form picks out with `entry.resource.ofType(T)` or
        # `entry.resource.where(resourceType = 'T')`.
        def includes
          @includes ||= include_values.flat_map { |value| targets_of(value) }
        end

        # The `_include` target types other than the query's own.
        def other_include_types
          @other_include_types ||= includes.map { |include| include[:target] } - [@resource_type]
        end

        private

        def include_values
          query = @variable[:expression]
          QuerySearch.other_includes(query).each do |name, value|
            log("skipping #{name}=#{value} in #{label}: only _include of #{@resource_type} is traced")
          end
          QuerySearch.includes(query)
        end

        def targets_of(value)
          source, param, explicit = value.split(':', 3)
          targets, target_by = explicit ? [[explicit], 'explicit'] : implied_targets(source, param)
          log("unresolved #{label} include #{value}: no target type") if targets.empty?
          targets.map { |target| { value:, target:, target_by: } }
        end

        def implied_targets(source, param)
          from_param = Array(@ig_resources.search_param_by_resource_and_code(source, param)&.target)
          from_param.any? ? [from_param, 'search_parameter'] : [of_types, 'of_type']
        end

        # The types other than the query's own that the form names on
        # `%Name.entry` or `%Name.entry.resource`, in the query's scope.
        def of_types
          name = @variable[:name]
          fhirpath = @form.fhirpath
          expressions.select { |expression| fhirpath.references(expression).include?(name) }
                     .flat_map { |expression| fhirpath.paths(expression, name, bundle: true) }
                     .flat_map { |chain| chain[:types] }.uniq - [@resource_type]
        end

        # Variables are `variable` extensions, so the owners' expressions
        # include them.
        def expressions
          @form.scope(@variable[:owner]).flat_map do |owner|
            @form.expressions(owner).map { |expression| expression[:expression] }
          end
        end

        def log(message)
          QuestionnaireUsageTracing.log(message)
        end
      end

      # One `templateExtract` extension and the contained template it points to.
      #
      # A PATCH template (with the smartforms `TemplateExtractExtensionPatchRequestUrl`
      # sub-extension) is a FHIRPath Patch `Parameters` resource. Its target type
      # comes from the operations' `path`, or else from the request URL, like
      # `'Condition/' + ...`. It fixes no codes.
      class Template
        PATCH_URL_SUFFIX = '/TemplateExtractExtensionPatchRequestUrl'

        attr_reader :reference

        def initialize(form, extract)
          @form = form
          @extract = extract
          parts = extract[:extension]['extension'].to_a
          @reference = parts.find { |part| part['url'] == 'template' }&.dig('valueReference', 'reference').to_s
          @patch_url = parts.find { |part| part['url'].to_s.end_with?(PATCH_URL_SUFFIX) }&.dig('valueString')
          @template = form.contained(@reference.delete_prefix('#'))
        end

        def found?
          !@template.nil?
        end

        def patch?
          !@patch_url.nil?
        end

        def label
          "#{@form.label} templateExtract #{@reference} on #{@extract[:defined_at]}"
        end

        def resource_type
          patch? ? patch_target : @template['resourceType']
        end

        def codes
          patch? ? {} : ProfileMatcher.from_template(@template)[:codes]
        end

        def entry(matched_by)
          owner = @extract[:owner]
          used_in = @form.root?(owner) ? [] : [Form.usage(owner, 'templateExtract')]
          { source: 'template_extract', **@form.header, name: @template['id'] || @reference.delete_prefix('#'),
            defined_at: @extract[:defined_at], template_codes:, patch: patch?, matched_by:, used_in: }
        end

        private

        def template_codes
          codes.fetch(:code) { [] }.map { |coding| [coding[:system], coding[:code]].compact.join('|') }
        end

        def patch_target
          paths = @template['parameter'].to_a.flat_map { |parameter| parameter['part'].to_a }
                                        .filter_map { |part| part['valueString'] if part['name'] == 'path' }
          paths.first&.split('.')&.first || @patch_url[%r{\A\s*'([A-Za-z]+)/}, 1]
        end
      end

      # The usages of one source in one form: the items in its scope that read
      # it, directly or through aliases, and the element paths they read.
      #
      # An alias is a `text/fhirpath` variable whose expression reads the source
      # or another alias. Its prefix is the parent's prefix plus the path of its
      # own chain, or `nil` when that chain stopped (see `Ast::ChainPath`). It
      # keeps the chain's type, and only chains whose type `accept` takes count.
      # A chain's own type counts only on a name that is a resource, or Bundle
      # entries, with the prefix `""`. An alias of a chain that ends at Bundle
      # entries, like `%q.entry.where(resource is Condition)`, is entries too.
      class Usages
        Name = Struct.new(:name, :owner, :bundle, :type, :prefix, :alias, keyword_init: true)

        # `source` is `{ name:, owner:, bundle: }`. `bundle: true` for a query,
        # whose `%Name` is a Bundle. `Ast::ChainPath` lists the values.
        def initialize(form, source, accept)
          @form = form
          @accept = accept
          @source = Name.new(**source, type: nil, prefix: '', alias: false)
          @names = [@source]
          @paths = []
        end

        # `[used_in, elements_read]`
        def call
          resolve_aliases
          used_in = @form.scope(@source.owner).flat_map { |owner| item_usages(owner) }
          [used_in.uniq, @paths.reject(&:empty?).uniq]
        end

        private

        # Repeats until no new alias is found. Each variable becomes an alias at
        # most once, so a form whose variables reference each other can't loop.
        def resolve_aliases
          pending = @form.fhirpath_variables.select { |variable| @form.covers?(@source.owner, variable[:owner]) }
          loop do
            break unless pending.reject! { |variable| add_alias(variable) }
          end
        end

        def add_alias(variable)
          reads = reads_of(variable[:expression], variable[:owner])
          return add_mixed_alias(variable) if reads.empty?

          name, chain = reads.first
          @paths.concat(reads.flat_map { |read| read_paths(*read) })
          add_name(variable, chain, type: type_of(name, chain), prefix: chain[:stopped] ? nil : read_path(name, chain))
        end

        # A variable that picks resources of several types, like
        # `%q.entry.resource.where(intent = 'order' or resourceType = 'Medication')`,
        # reads the source through an untyped chain that `accept` may reject.
        # It still becomes an alias, with no paths of its own, so a typed chain
        # from it, like `%name.where(resourceType = 'Medication')`, counts.
        def add_mixed_alias(variable)
          return false if @accept.call(nil)

          untyped = reads_of(variable[:expression], variable[:owner], accept: lambda(&:nil?))
          _name, chain = untyped.find { |name, read| resource?(name, read) }
          return false unless chain

          add_name(variable, chain, type: nil, prefix: '')
        end

        def add_name(variable, chain, type:, prefix:)
          @names << Name.new(name: variable[:name], owner: variable[:owner], bundle: chain[:entries] ? :entries : false,
                             alias: true, type:, prefix:)
          true
        end

        def resource?(name, chain)
          name.prefix == '' && chain[:path].empty? && !chain[:stopped]
        end

        # One usage per expression that reads the source. `via` names the alias
        # it went through, and is left out when the expression reads the source
        # directly. `reads` lists the element paths the expression reads, and is
        # left out when it reads none.
        def item_usages(item)
          usage_expressions(item).filter_map do |expression|
            reads = reads_of(expression[:expression], item)
            next if reads.empty?

            paths = reads.flat_map { |read| read_paths(*read) }
            @paths.concat(paths)
            Form.usage(item, expression[:extension], via: via(reads.map(&:first)), reads: paths.reject(&:empty?).uniq)
          end
        end

        # A root variable is not a usage: the items that read it are.
        def usage_expressions(item)
          expressions = @form.expressions(item)
          @form.root?(item) ? expressions.reject { |expression| expression[:extension] == 'variable' } : expressions
        end

        def via(names)
          names.first.name if names.all?(&:alias)
        end

        # `[name, chain]` for each accepted chain in the expression from a name
        # visible at `node`.
        def reads_of(expression, node, accept: @accept)
          references = @form.fhirpath.references(expression)
          @names.select { |name| references.include?(name.name) && @form.covers?(name.owner, node) }
                .flat_map do |name|
            @form.fhirpath.paths(expression, name.name, bundle: name.bundle)
                 .filter_map { |chain| [name, chain] if accept.call(type_of(name, chain)) }
          end
        end

        def type_of(name, chain)
          name.type || (chain[:type] if name.prefix == '')
        end

        def read_path(name, chain)
          [name.prefix, chain[:path]].reject(&:empty?).join('.') if name.prefix
        end

        # The chain's path and the paths its criteria read, after the prefix.
        # None when the prefix is unknown.
        def read_paths(name, chain)
          return [] unless name.prefix

          [chain[:path], *chain[:criteria]].map { |path| [name.prefix, path].reject(&:empty?).join('.') }
        end
      end

      # A questionnaire as a Hash, with the walks the tracer needs. The root and
      # the items that can define variables are its "owners".
      #
      # A usage on the root, like a root `itemExtractionContext`, has no
      # `link_id` or `text`: every item has a `linkId`, and the root's `text` is
      # its narrative.
      class Form
        VARIABLE_URL = 'http://hl7.org/fhir/StructureDefinition/variable'
        LAUNCH_CONTEXT_URL = 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-launchContext'
        TEMPLATE_EXTRACT_URL = 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-templateExtract'
        FHIRPATH = 'text/fhirpath'
        QUERY = 'application/x-fhir-query'

        def self.usage(item, extension, via: nil, reads: [])
          text = item['text'] if item['text'].is_a?(String)
          { link_id: item['linkId'], text:, extension:, via:, reads: (reads unless reads.empty?) }.compact
        end

        def initialize(questionnaire)
          @questionnaire = questionnaire
        end

        # The form's parsed FHIRPath, shared by every source traced in it.
        def fhirpath = (@fhirpath ||= Ast::Cache.new)

        # The `id` stands in for a missing `url`, so forms without one stay apart.
        def header
          url = @questionnaire['url']
          { questionnaire_url: url, questionnaire_id: (@questionnaire['id'] unless url),
            questionnaire_version: @questionnaire['version'], questionnaire_title: @questionnaire['title'] }.compact
        end

        def label
          @questionnaire['title'] || @questionnaire['url'] || @questionnaire['id']
        end

        # The x-fhir-query `variable` extensions on the root and on items, in
        # document order.
        def query_variables
          variables_in(QUERY)
        end

        # `{ name:, types:, owner:, defined_at: }` for each `launchContext`
        # extension on the root. The name is in `valueCoding.code`, or in
        # `valueId` in older SDC versions. Each `type` sub-extension adds a type.
        def launch_contexts
          list(@questionnaire['extension']).select { |extension| extension['url'] == LAUNCH_CONTEXT_URL }
                                           .filter_map { |extension| launch_context(list(extension['extension'])) }
        end

        # `{ extension:, owner:, defined_at: }` for each `templateExtract`
        # extension on the root and on items, in document order.
        def template_extracts
          owners.flat_map do |owner|
            list(owner['extension']).select { |extension| extension['url'] == TEMPLATE_EXTRACT_URL }
                                    .map { |extension| { extension:, owner:, defined_at: defined_at(owner) } }
          end
        end

        # The contained resource with this `id`, or `nil`.
        def contained(id)
          list(@questionnaire['contained']).find { |resource| resource['id'] == id }
        end

        def root?(owner)
          owner.equal?(@questionnaire)
        end

        # The `text/fhirpath` `variable` extensions, in document order.
        def fhirpath_variables
          @fhirpath_variables ||= variables_in(FHIRPATH)
        end

        # The owner and the items under it: the root and every item for a root
        # variable, the item and its children for an item variable.
        def scope(owner)
          [owner, *descendants(owner)]
        end

        # Whether a variable defined on `owner` (the root or an item) is visible
        # at `node`.
        def covers?(owner, node)
          return true if owner.equal?(@questionnaire)

          node = parents[node] until node.nil? || node.equal?(owner)
          !node.nil?
        end

        # `{ extension:, expression: }` for each `text/fhirpath` expression in
        # the item's own extensions and their sub-extensions. Nested items are
        # not read. `extension` is the short name, like `initialExpression`.
        def expressions(item)
          list(item['extension']).flat_map { |extension| extension_expressions(extension, short_name(extension)) }
        end

        private

        def extension_expressions(extension, name)
          value = extension['valueExpression']
          own = value && value['language'] == FHIRPATH && value['expression'] ? [value['expression']] : []
          own.map { |expression| { extension: name, expression: } } +
            list(extension['extension']).flat_map { |sub_extension| extension_expressions(sub_extension, name) }
        end

        def short_name(extension)
          extension['url'].to_s.split('/').last.to_s.delete_prefix('sdc-questionnaire-')
        end

        def launch_context(parts)
          name_part = parts.find { |part| part['url'] == 'name' } || {}
          name = name_part.dig('valueCoding', 'code') || name_part['valueId']
          types = parts.select { |part| part['url'] == 'type' }.filter_map { |part| part['valueCode'] }
          { name:, types:, owner: @questionnaire, defined_at: 'root' } if name
        end

        def variables_in(language)
          owners.flat_map do |owner|
            variables(owner).select { |expression| expression['language'] == language }.map do |expression|
              { name: expression['name'], expression: expression['expression'].to_s, owner:,
                defined_at: defined_at(owner) }
            end
          end
        end

        def variables(owner)
          list(owner['extension']).select { |extension| extension['url'] == VARIABLE_URL }
                                  .filter_map { |extension| extension['valueExpression'] }
        end

        def parents
          @parents ||= owners.each_with_object({}.compare_by_identity) do |node, map|
            list(node['item']).each { |child| map[child] = node }
          end
        end

        def defined_at(owner)
          owner.equal?(@questionnaire) ? 'root' : owner['linkId']
        end

        # The root and every item, in document order.
        def owners
          [@questionnaire, *descendants(@questionnaire)]
        end

        def descendants(node)
          list(node['item']).flat_map { |item| [item, *descendants(item)] }
        end

        def list(value)
          value.is_a?(Array) ? value : []
        end
      end
    end
  end
end
