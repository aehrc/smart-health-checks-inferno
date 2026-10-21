# frozen_string_literal: true

require 'fhirpath'
require_relative 'log'

module InfernoSuitePlugins
  module QuestionnaireUsageTracing
    # Reads `%Name` references and element paths from FHIRPath expressions.
    #
    # Each reader takes an expression, and has an `_in` variant that takes the
    # tree `parse` returns, so a caller that keeps trees parses each expression
    # once.
    module Ast
      module_function

      # The `%Name` names the expression references, without duplicates.
      def references(expression)
        references_in(parse(expression))
      end

      def references_in(tree)
        nodes(tree).filter_map { |node| constant_name(node) }.uniq
      end

      # One `{ type:, types:, path:, stopped:, criteria: }` per longest chain
      # that starts with `%name`, including chains nested in function
      # arguments. `ChainPath` says what each key holds, and what `bundle:`
      # takes.
      def paths(expression, name, bundle:)
        paths_in(parse(expression), name, bundle:)
      end

      def paths_in(tree, name, bundle:)
        chains(tree, name).map { |steps| ChainPath.read(steps, bundle:) }
      end

      # The tree, or `{}` for an empty expression or one that doesn't parse.
      def parse(expression)
        return {} if expression.to_s.strip.empty?

        Fhirpath::Parser.parse(expression)
      rescue Fhirpath::Error => e
        QuestionnaireUsageTracing.log("skipping FHIRPath #{expression.inspect}: #{e.message}")
        {}
      end

      def nodes(node, found = [])
        return found unless node.is_a?(Hash)

        found << node
        children(node).each { |child| nodes(child, found) }
        found
      end

      # Step lists of the longest chains from `%name`.
      def chains(node, name, found = [])
        return found unless node.is_a?(Hash)

        steps = chain_steps(node, name)
        nested = steps ? steps.flat_map { |step| step[:args] } : children(node)
        found << steps if steps
        nested.each { |child| chains(child, name, found) }
        found
      end

      def chain_steps(node, name)
        steps_from(node) { |term| [] if constant_name(term.dig('children', 0, 'children', 0)) == name }
      end

      # The steps of the chain that ends at `node`. The block takes the
      # `TermExpression` the chain starts at, and returns the steps the start
      # gives, or `nil` when the chain is not one to read.
      def steps_from(node, &)
        case node['type']
        when 'InvocationExpression', 'IndexerExpression'
          base, step = children(node)
          steps = steps_from(base, &)
          steps && [*steps, step(node['type'], step)]
        when 'TermExpression' then yield node
        end
      end

      # The element paths `node`, an argument of `where`, `exists`, `all` or
      # `select`, reads relative to the element it is evaluated on, like
      # `code` and `status` in `where(code.memberOf('...') and status = 'final')`.
      # A chain that starts anywhere else, like `%name` or `now()`, is
      # evaluated on its own start, so only the arguments of that start are read.
      def criteria_paths(node)
        return [] unless node.is_a?(Hash)

        steps = steps_from(node) { |term| relative_start(term) }
        return ChainPath.relative_paths(steps) if steps

        starts_elsewhere = %w[InvocationExpression IndexerExpression].include?(node['type'])
        (starts_elsewhere ? children(node).first(1) : children(node)).flat_map { |child| criteria_paths(child) }
      end

      # The steps a chain from `$this` (none) or from a member starts with.
      def relative_start(term)
        start = children(term).first
        invocation = children(start).first if start&.dig('type') == 'InvocationTerm'
        case invocation&.dig('type')
        when 'MemberInvocation' then [step('InvocationExpression', invocation)]
        when 'ThisInvocation' then []
        end
      end

      def step(expression_type, node)
        return { kind: :index, args: [node] } if expression_type == 'IndexerExpression'

        case node['type']
        when 'MemberInvocation' then { kind: :member, name: identifier(children(node).first), args: [] }
        when 'FunctionInvocation' then function_step(children(node).first)
        else { kind: :other, args: [] }
        end
      end

      def function_step(functn)
        name_node, param_list = children(functn)
        { kind: :function, name: identifier(name_node), args: param_list ? children(param_list) : [] }
      end

      # `%name`, `` %`vs-x` `` and `%'vs-x'` all give the bare name.
      def constant_name(node)
        return unless node.is_a?(Hash) && node['type'] == 'ExternalConstant'

        name = node.dig('children', 0, 'text') || node['terminalNodeText'].to_a.last
        name.to_s.delete_prefix('%').delete_prefix('`').delete_suffix('`').delete_prefix("'").delete_suffix("'")
      end

      def identifier(node)
        node&.dig('text').to_s.delete_prefix('`').delete_suffix('`')
      end

      def children(node)
        node['children'] || []
      end

      # `references` and `paths` that read each expression once, however many
      # sources and aliases read it.
      class Cache
        def initialize
          @trees = {}
          @references = {}
          @paths = {}
        end

        def references(expression)
          @references[expression] ||= Ast.references_in(tree(expression))
        end

        def paths(expression, name, bundle:)
          @paths[[expression, name, bundle]] ||= Ast.paths_in(tree(expression), name, bundle:).freeze
        end

        private

        def tree(expression)
          @trees[expression] ||= Ast.parse(expression)
        end
      end

      # Turns the steps of one chain into `{ type:, types:, path:, stopped:, criteria: }`:
      #
      # - `type`: the one resource type the chain picks, or `nil`
      # - `types`: every resource type the chain names, including each branch
      #   of a `where(... or resourceType = 'T')` that picks several
      # - `path`: the member path, which ends where the chain stops
      # - `stopped`: whether it stopped at `ofType` or `select`, or left the
      #   resource at `resolve`, `children` or `descendants`
      # - `criteria`: the paths the arguments of `where`, `exists`, `all` and
      #   `select` read, like `status` in `where(status = 'final')`
      #
      # A chain that ends at Bundle entries, like
      # `%q.entry.where(resource is Condition)`, also has `entries: true`.
      #
      # `bundle:` says what the chain starts at: `true` for a Bundle,
      # `:entries` for Bundle entries, and `false` for a resource.
      module ChainPath
        STOP_FUNCTIONS = %w[ofType select resolve children descendants].freeze
        CRITERIA_FUNCTIONS = %w[where exists all select].freeze
        EXTENSION_MEMBERS = %w[extension modifierExtension].freeze
        # The functions that pick some of the Bundle entries, as an indexer does.
        ENTRY_PICKS = %w[where first last tail skip take single].freeze
        # A chain that reads the Bundle itself instead of a resource in it.
        BUNDLE_READ = { type: nil, types: [], path: '', stopped: true, criteria: [] }.freeze

        module_function

        def read(steps, bundle:)
          case bundle
          when :entries then read_entries(steps)
          when true then read_bundle(steps)
          else read_path(steps)
          end
        end

        # The path and criteria paths of a chain inside a criteria argument,
        # without `resourceType`, which is not an element.
        def relative_paths(steps)
          read = read_path(steps)
          [read[:path], *read[:criteria]].reject { |path| path.empty? || resource_type_path?(path) }
        end

        # A Bundle chain reads a resource through `entry` and then `resource`.
        # A chain that never reaches `entry`, like `%q.total`, reads the
        # Bundle, so it reads no profile element. It counts as stopped, so an
        # alias of it gets no prefix.
        def read_bundle(steps)
          member?(steps.first, 'entry') ? read_entries(steps.drop(1)) : BUNDLE_READ
        end

        # The steps after `entry`. Functions and indexers before `resource`
        # pick entries, and a `where(resource is T)` among them gives the type,
        # as does an `ofType(T)` right after `resource`.
        #
        # A chain that only picks entries, like
        # `%q.entry.where(resource is Condition)`, ends at entries, so an alias
        # of it reads `resource` the same way. One that does something else
        # with them, like `%q.entry.count()` or `%q.entry.fullUrl`, reads the
        # Bundle.
        def read_entries(steps)
          between = steps.take_while { |step| step[:kind] != :member }
          rest = steps.drop(between.size)
          return read_resource(rest.drop(1), entry_type(between)) if member?(rest.first, 'resource')
          return BUNDLE_READ unless rest.empty? && between.all? { |step| entry_pick?(step) }

          type = entry_type(between)
          { type:, types: [type].compact, path: '', stopped: false, criteria: [], entries: true }
        end

        def entry_type(between)
          between.filter_map { |step| entry_filter_type(step) }.last
        end

        def entry_pick?(step)
          step[:kind] == :index || (step[:kind] == :function && ENTRY_PICKS.include?(step[:name]))
        end

        # The steps after `resource`, with the type an entry filter gave.
        def read_resource(steps, filter_type)
          of_type = type_name(steps.shift) if function?(steps.first, 'ofType')
          read = read_path(steps)
          read.merge(type: of_type || filter_type || read[:type],
                     types: [of_type, filter_type, *read[:types]].compact.uniq)
        end

        # The `T` of `where(resource is T)` or `where(resource.is(T))`.
        def entry_filter_type(step)
          return unless function?(step, 'where') && step[:args].one?

          condition = step[:args].first
          case condition['type']
          when 'TypeExpression' then type_of_is_operator(condition)
          when 'InvocationExpression' then type_of_is_call(condition)
          end
        end

        def type_of_is_operator(condition)
          term, specifier = Ast.children(condition)
          return unless condition['terminalNodeText'].to_a == ['is'] && term&.dig('text') == 'resource'

          clean_type(specifier&.dig('text'))
        end

        def type_of_is_call(condition)
          term, invocation = Ast.children(condition)
          return unless term&.dig('text') == 'resource' && invocation&.dig('type') == 'FunctionInvocation'

          step = Ast.function_step(Ast.children(invocation).first)
          type_name(step) if step[:name] == 'is'
        end

        def read_path(steps)
          StepReader.new.read(steps)
        end

        def resource_type_path?(path)
          path.split('.').last == 'resourceType'
        end

        # The `X` of a `url = 'X'` condition in the single argument. The
        # condition can sit inside `and`, parentheses or an unqualified
        # `exists(...)`, as in `where(exists(url = 'X') and ...)`. A condition
        # inside another chain, like `extension.where(url = 'Y')`, is about a
        # sub-extension and is not taken.
        def url_filter(args)
          url_condition(args.first) if args.one?
        end

        def url_condition(node)
          case node&.dig('type')
          when 'EqualityExpression' then url_equality(node)
          when 'AndExpression', 'ParamList', 'ParenthesizedTerm'
            Ast.children(node).lazy.filter_map { |child| url_condition(child) }.first
          when 'TermExpression', 'InvocationTerm' then url_condition(Ast.children(node).first)
          when 'FunctionInvocation' then url_exists(*Ast.children(Ast.children(node).first))
          end
        end

        def url_equality(node)
          left, right = Ast.children(node)
          string_literal(right) if node['terminalNodeText'].to_a == ['='] && left&.dig('text') == 'url'
        end

        # Reached only for an unqualified call: a qualified one is the right
        # child of an `InvocationExpression`, which `url_condition` skips.
        def url_exists(name, params = nil)
          url_condition(params) if Ast.identifier(name) == 'exists'
        end

        def string_literal(node)
          node&.dig('text').to_s[/\A'(.*)'\z/m, 1]
        end

        def type_name(step)
          clean_type(step[:args].first&.dig('text'))
        end

        def clean_type(text)
          text.to_s.delete('`').delete_prefix('FHIR.')
        end

        def function?(step, name)
          step && step[:kind] == :function && step[:name] == name
        end

        def member?(step, name)
          step && step[:kind] == :member && step[:name] == name
        end
      end

      # Reads the steps after the start of one chain, for `ChainPath.read_path`.
      class StepReader
        def initialize
          @names = []
          @criteria = []
          @types = []
          @type = nil
        end

        def read(steps)
          stopped = false
          steps.each do |step|
            stopped = read_step(step)
            break if stopped
          end
          { type: @type, types: @types.uniq, path: @names.join('.'), stopped:, criteria: @criteria.uniq }
        end

        private

        # Whether the chain stops at this step.
        def read_step(step)
          case step[:kind]
          when :member
            @names << step[:name]
            false
          when :function
            read_function(step) unless extension_filter(step)
            ChainPath::STOP_FUNCTIONS.include?(step[:name])
          else false
          end
        end

        def read_function(step)
          read_criteria(step) if ChainPath::CRITERIA_FUNCTIONS.include?(step[:name])
          read_resource_type(step[:args].first) if step[:name] == 'where' && step[:args].one? && @names.empty?
        end

        def read_criteria(step)
          prefix = @names.join('.')
          paths = step[:args].flat_map { |arg| Ast.criteria_paths(arg) }
          @criteria.concat(paths.map { |path| [prefix, path].reject(&:empty?).join('.') })
        end

        # A `where(resourceType = 'T')` on the start of the chain picks
        # resources of type `T`.
        def read_resource_type(condition)
          @type ||= required_type(condition)
          @types.concat(named_types(condition))
        end

        # The `T` a `where` condition requires with `resourceType = 'T'`, alone
        # or as a branch of an `and`.
        def required_type(condition)
          case condition&.dig('type')
          when 'EqualityExpression' then resource_type_equality(condition)
          when 'AndExpression', 'TermExpression', 'ParenthesizedTerm'
            Ast.children(condition).lazy.filter_map { |child| required_type(child) }.first
          end
        end

        # Every `T` of a `resourceType = 'T'` in a `where` condition, in any
        # branch of an `and` or an `or`.
        def named_types(condition)
          case condition&.dig('type')
          when 'EqualityExpression' then [resource_type_equality(condition)].compact
          when 'AndExpression', 'OrExpression', 'TermExpression', 'ParenthesizedTerm'
            Ast.children(condition).flat_map { |child| named_types(child) }
          else []
          end
        end

        def resource_type_equality(node)
          left, right = Ast.children(node)
          return unless node['terminalNodeText'].to_a == ['='] && left&.dig('text') == 'resourceType'

          ChainPath.string_literal(right)
        end

        # Folds the url of an extension filter into the path, and says
        # whether it did.
        def extension_filter(step)
          if step[:name] == 'extension' && (url = ChainPath.string_literal(step[:args].first))
            @names << "extension[url=#{url}]"
          elsif step[:name] == 'where' && ChainPath::EXTENSION_MEMBERS.include?(@names.last) &&
                (url = ChainPath.url_filter(step[:args]))
            @names[-1] = "#{@names.last}[url=#{url}]"
          end
        end
      end
    end
  end
end
