# frozen_string_literal: true

require 'fhir_models'
require 'uri'

module InfernoSuitePlugins
  module QuestionnaireUsageTracing
    # Reads the type and search parameters of an x-fhir-query.
    module QuerySearch
      # Parameters that shape the result instead of selecting resources.
      RESULT_PARAMS = %w[_sort _include _revinclude _count _elements _summary _total _contained _containedType].freeze
      # One `name=value` pair. A `{{...}}` template can hold `&`, FHIRPath's
      # string concatenation, so it is kept whole.
      PAIR = /(?:\{\{.*?\}\}|[^&])+/

      module_function

      # `{ resource_type:, read: }`. The type is the last path segment that names
      # a resource type, so `Patient/{{%patient.id}}` and the compartment search
      # `Patient/{{%patient.id}}/Observation?...` give `Patient` and
      # `Observation`. Without one it is the last segment. The query is a read,
      # which gives one resource instead of a Bundle, when an id follows the type.
      # An operation, like `Patient/{{%patient.id}}/$everything` or
      # `Observation/$lastn`, gives a Bundle, so it is not a read.
      def target(query)
        segments = path_segments(query)
        index = type_index(segments)
        return { resource_type: segments.last, read: false } unless index

        following = segments[index + 1]
        read = !following.nil? && !following.start_with?('_', '$') && segments.none? { |s| s.start_with?('$') }
        { resource_type: segments[index], read: }
      end

      # The parameter names that select resources, without modifiers. A
      # compartment search, like `Patient/{{%patient.id}}/Observation?code=x`,
      # also selects by its compartment, so it gives `patient` too.
      def params(query)
        names = pairs(query).map { |name, _value| name.split(':').first }
        [*compartment_param(query), *names].uniq - RESULT_PARAMS
      end

      # The `_include` values of the query's own type, like
      # `PractitionerRole:location` on a PractitionerRole search. These are
      # the ones the tracer traces.
      def includes(query)
        type = target(query)[:resource_type]
        pairs(query).filter_map { |name, value| value if own_include?(name, value, type) }
      end

      # The `[name, value]` pairs of the `_include` parameters `includes` leaves
      # out: `_include:iterate`, and includes from other types.
      def other_includes(query)
        type = target(query)[:resource_type]
        pairs(query).select { |name, value| name.start_with?('_include') && !own_include?(name, value, type) }
      end

      # `[name, value]` for each search parameter, decoded. A parameter without
      # `=` has the value `""`.
      def pairs(query)
        query.to_s.split('?', 2)[1].to_s.scan(PAIR).map do |pair|
          name, value = pair.split('=', 2)
          [decode(name.to_s), decode(value.to_s)]
        end
      end

      def own_include?(name, value, type)
        name == '_include' && value.split(':').first == type
      end

      def compartment_param(query)
        segments = path_segments(query)
        index = type_index(segments)
        compartment = segments[index - 2] if index && index >= 2
        compartment.downcase if FHIR::RESOURCES.include?(compartment)
      end

      def path_segments(query)
        query.to_s.split('?', 2).first.to_s.split('/')
      end

      def type_index(segments)
        segments.rindex { |segment| FHIR::RESOURCES.include?(segment) }
      end

      def decode(text)
        URI.decode_uri_component(text)
      rescue ArgumentError
        text
      end
    end
  end
end
