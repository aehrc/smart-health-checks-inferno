# frozen_string_literal: true

require_relative 'support'

module InfernoSuitePlugins
  module QuestionnaireUsageTracing
    # Verifies `Tracer` traces an `_include` whose resources the form picks
    # with `where(resourceType = 'T')`, like the 715 Absolute CVD Risk module,
    # which picks the requests and the included Medications in one variable and
    # the Medications out of it again.
    class TracerMixedIncludeTest < Minitest::Test
      include TracerFixtures

      MEDICATION_REQUEST = 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-medicationrequest'
      MEDICATION = 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-medication'
      QUERY = 'MedicationRequest?patient={{%patient.id}}&_include=MedicationRequest:medication'
      MEDS = "%MedicationRequest.entry.resource.where(intent = 'order' or resourceType = 'Medication')"

      def test_a_target_type_from_where_resource_type_in_the_form
        entry = traces[MEDICATION].first

        assert_equal 'of_type', entry[:target_by]
        assert_equal ['code'], entry[:elements_read]
        assert_equal [['insulin'], ['meds']], [link_ids(entry), vias(entry)]
      end

      def test_untyped_chains_of_a_variable_of_several_types_stay_with_the_query_entry
        entry = traces[MEDICATION_REQUEST].first

        assert_equal ['recent'], link_ids(entry)
        assert_equal %w[intent authoredOn], entry[:elements_read]
      end

      private

      def traces
        trace(form, profiles: { MEDICATION_REQUEST => profile('MedicationRequest'),
                                MEDICATION => profile('Medication') })
      end

      def form
        questionnaire(
          extension: [query_variable('MedicationRequest', QUERY), fhirpath_variable('meds', MEDS)],
          item: [item('insulin', 'Insulin', expression('initialExpression',
                                                       "%meds.where(resourceType = 'Medication' and code.exists())")),
                 item('recent', 'Recent', expression('initialExpression',
                                                     '%meds.where(authoredOn > now() - 12 months).exists()'))]
        )
      end
    end
  end
end
