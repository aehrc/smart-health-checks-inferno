# frozen_string_literal: true

require_relative 'query_search'

module InfernoSuitePlugins
  module QuestionnaireUsageTracing
    # The "Used in questionnaires" Markdown for one group's trace entries: a
    # nested list of questionnaires, the sources in each that link to the
    # profile, and the items that use each source. It uses only bold and plain
    # text, since Inferno shows tables without borders and raw HTML as text.
    #
    # A source no item uses is left out, unless it is a query that fetches
    # other resources through `_include` or a template extracted from the
    # whole form. So are uses that only define a variable: the items that read
    # the variable are listed instead. Element paths the profile neither marks
    # Must Support nor requires are marked "(not checked)".
    class UsageSection
      NOT_CHECKED = '(not checked)'

      def initialize(entries, group)
        @group = group
        @must_support = MustSupport.new(group)
        @forms = entries.select { |entry| shown?(entry) }.group_by do |entry|
          entry.values_at(:questionnaire_url, :questionnaire_id, :questionnaire_version)
        end
      end

      def empty?
        @forms.empty?
      end

      def markdown
        lines = ['## Used in questionnaires', '', intro, '']
        @forms.each_value do |entries|
          lines.push("- **#{form_title(entries.first)}**", *entries.flat_map { |entry| entry_lines(entry) })
        end
        "#{lines.join("\n")}\n"
      end

      private

      def intro
        "These questionnaires in the IG read or create #{@group.profile_name || @group.resource} resources. A " \
          'form can pre-fill an item only if the server returns the elements the item reads. Elements marked ' \
          "#{NOT_CHECKED} are neither Must Support nor required by the profile, so this group's tests do not " \
          'check them.'
      end

      def shown?(entry)
        !item_lines(entry).empty? || entry[:source] == 'template_extract' ||
          (entry[:source] == 'query' && QuerySearch.includes(entry[:query]).any?)
      end

      def item_lines(entry)
        ItemLines.new(entry[:used_in].to_a, @must_support)
      end

      # The title, or the URL or id for an untitled form, with the version when
      # another questionnaire shown has the same title, as an assembled modular
      # form does.
      def form_title(entry)
        title = title_of(entry)
        version = entry[:questionnaire_version]
        same_title = @forms.values.count { |entries| title_of(entries.first) == title }
        same_title > 1 && version ? "#{title}, version #{version}" : title
      end

      def title_of(entry)
        entry[:questionnaire_title] || entry[:questionnaire_url] || entry[:questionnaire_id] || 'Untitled questionnaire'
      end

      def entry_lines(entry)
        ["  - #{heading(entry)}", *details(entry).map { |line| "    - #{line}" }]
      end

      def heading(entry)
        name = entry[:name]
        resource = @group.resource
        case entry[:source]
        when 'query' then "**Query #{name}**: #{query_action(entry)}"
        when 'include' then "**Query #{name}**: fetches #{resource} resources through _include=#{entry[:include]}"
        when 'launch_context' then "**Launch context #{name}**: the #{resource} the form is opened for"
        when 'template_extract' then "**Extraction template #{name}**: #{template_action(entry)}"
        end
      end

      def query_action(entry)
        entry[:read] ? "reads one #{@group.resource} by id" : "searches #{@group.resource} resources"
      end

      def template_action(entry)
        resource = @group.resource
        return "updates an existing #{resource} with a FHIRPath Patch" if entry[:patch]

        codes = entry[:template_codes].to_a
        "creates a new #{resource}#{" with code #{codes.join(', ')}" unless codes.empty?} from the answers"
      end

      def details(entry)
        query = entry[:query]
        search = SearchCheck.new(query, @group).line if entry[:source] == 'query'
        [query && "Request: #{query}", search, *items(entry)].compact
      end

      def items(entry)
        lines = item_lines(entry)
        lines.empty? ? [unused(entry)] : lines.lines
      end

      def unused(entry)
        return 'Its answers come from the whole form' if entry[:source] == 'template_extract'

        "No item reads its results; it fetches #{QuerySearch.includes(entry[:query]).join(', ')} through _include"
      end
    end

    # One list line per item that uses a source, in document order, like
    # `**Height**: pre-fills the answer, shows or hides the item; reads value.value`.
    # An item that uses the source in several extensions gets one line. Uses
    # that only define a variable are left out.
    class ItemLines
      MAX = 25
      HIDDEN_USES = %w[variable].freeze
      ROOT_LABEL = 'The whole form'

      # What an item does with the source, by the short name of the extension
      # whose expression reads it.
      USES = {
        'initialExpression' => 'pre-fills the answer',
        'calculatedExpression' => 'calculates the answer',
        'itemPopulationContext' => 'sets the population context',
        'enableWhenExpression' => 'shows or hides the item',
        'answerExpression' => 'lists the answer options',
        'candidateExpression' => 'suggests answers',
        'contextExpression' => 'gives context for answering',
        'itemExtractionContext' => 'sets the extraction context',
        'templateExtract' => 'its answers fill the template'
      }.freeze

      def initialize(usages, must_support)
        @items = usages.reject { |usage| HIDDEN_USES.include?(usage[:extension]) }
                       .group_by { |usage| usage[:link_id] }.values
        @must_support = must_support
      end

      def empty?
        @items.empty?
      end

      # Up to `MAX` lines, then one that counts the rest.
      def lines
        more = @items.size - MAX
        [*@items.first(MAX).map { |usages| line(usages) },
         ("and #{more} more items, listed in plugins.yml" if more.positive?)].compact
      end

      private

      # Leaves out a part the item has nothing for.
      def line(usages)
        details = [uses(usages), reads(usages)].compact.join('; ')
        "**#{label(usages.first)}**#{": #{details}" unless details.empty?}"
      end

      def uses(usages)
        names = usages.filter_map { |usage| usage[:extension] }.uniq
        names.map { |name| USES.fetch(name, name) }.join(', ') unless names.empty?
      end

      def reads(usages)
        paths = usages.flat_map { |usage| usage[:reads].to_a }.uniq
        "reads #{paths.map { |path| read_label(path) }.join(', ')}" unless paths.empty?
      end

      # The item's text, or its linkId when it has none. A usage with neither
      # is on the questionnaire root.
      def label(usage)
        text = usage[:text].to_s.split.join(' ')
        return text.gsub(/[*_`\[\]]/) { |match| "\\#{match}" } unless text.empty?

        usage[:link_id]&.to_s || ROOT_LABEL
      end

      # The path with an extension the profile does not slice shortened to the
      # last part of its URL, like `extension[individual-pronouns]`.
      def read_label(path)
        label = @must_support.label(path)
        shown = label.gsub(%r{\[url=(?:[^\]]*/)?([^\]/]+)\]}, '[\1]')
        @must_support.covered?(label) ? shown : "#{shown} #{UsageSection::NOT_CHECKED}"
      end
    end

    # Whether a group tests a search by the same parameters as an x-fhir-query,
    # in any order.
    class SearchCheck
      def initialize(query, group)
        @names = QuerySearch.params(query)
        @tested = group.searches.to_a.map { |search| search[:names] }
      end

      # A line for the list, or `nil` when the query selects by no parameter.
      def line
        return if @names.empty?

        same = @tested.find { |names| names.to_set == @names.to_set }
        return "This group tests the same search: #{label(same)}" if same

        "**Not tested by this group:** a search by #{label(@names)}#{others}"
      end

      private

      def others
        "; it tests #{@tested.map { |names| label(names) }.join(', ')}" unless @tested.empty?
      end

      def label(names)
        names.join(' + ')
      end
    end

    # The element paths a group's profile marks Must Support or requires, so
    # its Must Support or validation tests check them.
    #
    # Trace paths name an extension as `extension[url=U]`. `label` writes one
    # the profile slices as Must Support as `extension:sliceName`, like the
    # profile does. A path inside such an extension counts as checked, since
    # the extension's own profile defines what it holds.
    #
    # A trace path names a choice element by its type, like `valueQuantity`,
    # where the profile has `value[x]`, so `covered?` compares it as `value`.
    class MustSupport
      ALWAYS_PRESENT = %w[id].freeze
      EXTENSION_URL = /\A((?:modifierE|e)xtension)\[url=(.+)\]\z/
      EXTENSION_SLICE = /\A(?:modifierE|e)xtension:/

      def initialize(group)
        must_supports = group.must_supports || {}
        paths = element_paths(must_supports, group.mandatory_elements.to_a)
        @paths = paths.to_set { |path| plain(path) }
        @choices = choice_paths(paths)
        @slices = must_supports[:extensions].to_a.to_h { |extension| slice(extension) }
      end

      def label(path)
        segments(path).each_with_object([]) do |segment, done|
          _, member, url = segment.match(EXTENSION_URL).to_a
          done << (@slices[[done.join('.'), member, url]] || segment)
        end.join('.')
      end

      def covered?(label)
        ALWAYS_PRESENT.include?(label) || @paths.include?(without_choice_types(label)) ||
          segments(label).any? { |segment| segment.match?(EXTENSION_SLICE) }
      end

      private

      # Must Support element and slice paths are relative, like
      # `value[x]:valueQuantity.value` or `onset[x]` for an `onsetDateTime`
      # type slice; mandatory ones start with the type, like `Observation.status`.
      def element_paths(must_supports, mandatory)
        elements = must_supports[:elements].to_a + must_supports[:slices].to_a
        (elements.map { |element| element[:path] } + mandatory.map { |path| path.split('.', 2).last }).compact
      end

      # `[parent path, name]` for each choice element, like `["", "value"]`
      # for `value[x]:valueQuantity.value`.
      def choice_paths(paths)
        paths.filter_map do |path|
          parent, _, name = plain(path[/\A.*?\[x\]/]).rpartition('.') if path.include?('[x]')
          [parent, name] if name
        end.to_set
      end

      # The label with each segment that names a choice element by its type,
      # like `valueQuantity` or `effectiveDateTime`, written as the element.
      def without_choice_types(label)
        segments(label).each_with_object([]) do |segment, done|
          done << (choice_name(done.join('.'), segment) || segment)
        end.join('.')
      end

      def choice_name(parent, segment)
        @choices.find { |choice_parent, name| choice_parent == parent && segment.match?(/\A#{name}[A-Z]/) }&.last
      end

      # `[[parent path, member, url], "extension:sliceName"]` for an extension
      # with an id like `Patient.address.extension:foo`.
      def slice(extension)
        parent, _, segment = extension[:id].to_s.split('.', 2).last.to_s.rpartition('.')
        [[plain(parent), segment.split(':').first, extension[:url]], segment]
      end

      # A snapshot path without `[x]` and slice names, as trace paths are.
      def plain(path)
        path.gsub('[x]', '').gsub(/:[^.]+/, '')
      end

      # Dot-separated steps, keeping the dots inside `[url=...]` together.
      def segments(path)
        path.scan(/(?:[^.\[]+|\[[^\]]*\])+/)
      end
    end
  end
end
