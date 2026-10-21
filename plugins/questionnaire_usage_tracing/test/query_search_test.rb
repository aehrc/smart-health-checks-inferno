# frozen_string_literal: true

require_relative 'support'

module InfernoSuitePlugins
  module QuestionnaireUsageTracing
    # Verifies `QuerySearch` reads the type, search parameters and `_include`
    # values of x-fhir-queries.
    class QuerySearchTest < Minitest::Test
      def test_an_ampersand_inside_a_template_does_not_split_the_parameters
        query = "Observation?patient={{'Patient/' & %patient.id}}&code=1"

        assert_equal [['patient', "{{'Patient/' & %patient.id}}"], %w[code 1]], QuerySearch.pairs(query)
        assert_equal %w[patient code], QuerySearch.params(query)
      end

      def test_an_operation_is_not_a_read
        assert_equal({ resource_type: 'Patient', read: false },
                     QuerySearch.target('Patient/{{%patient.id}}/$everything'))
        assert_equal({ resource_type: 'Observation', read: false }, QuerySearch.target('Observation/$lastn?code=1'))
        assert_equal({ resource_type: 'Patient', read: true }, QuerySearch.target('Patient/{{%patient.id}}'))
      end

      def test_a_compartment_search_selects_by_its_compartment
        assert_equal %w[patient code], QuerySearch.params('Patient/{{%patient.id}}/Observation?code=x')
      end

      def test_includes_are_the_plain_includes_of_the_query_own_type
        query = 'PractitionerRole?_id=1&_include=PractitionerRole:location' \
                '&_include:iterate=Location:organization&_include=Location:partof'

        assert_equal ['PractitionerRole:location'], QuerySearch.includes(query)
        assert_equal [%w[_include:iterate Location:organization], %w[_include Location:partof]],
                     QuerySearch.other_includes(query)
      end
    end
  end
end
