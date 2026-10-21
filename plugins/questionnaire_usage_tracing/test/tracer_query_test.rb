# frozen_string_literal: true

require_relative 'support'

module InfernoSuitePlugins
  module QuestionnaireUsageTracing
    # Verifies `Tracer` finds the x-fhir-query variables that link a
    # questionnaire to a profile, and the items that use them.
    class TracerQueryTest < Minitest::Test
      include TracerFixtures

      def test_a_root_variable_used_by_an_item
        form = questionnaire(
          extension: [query_variable('ObsBodyHeight', HEIGHT_QUERY)],
          item: [item('height', 'Height',
                      expression('initialExpression', '%ObsBodyHeight.entry.resource.first().value.value'))]
        )

        assert_equal({ BODY_HEIGHT => [height_entry] }, trace(form))
      end

      def test_an_item_variable_is_used_only_within_that_item
        entry = trace(weight_in_a_group_form)[BODY_WEIGHT].first

        assert_equal 'vitals', entry[:defined_at]
        assert_equal ['weight'], link_ids(entry)
        assert_equal ['value'], entry[:elements_read]
      end

      def test_a_variable_that_no_item_uses_still_gets_an_entry
        form = questionnaire(extension: [query_variable('ObsBodyHeight', HEIGHT_QUERY)],
                             item: [item('height', 'Height')])
        entry = trace(form)[BODY_HEIGHT].first

        assert_empty entry[:used_in]
        assert_empty entry[:elements_read]
      end

      def test_a_read_links_to_every_group_of_its_type_and_reads_the_resource_itself
        traces = trace(patient_read_form,
                       profiles: { AU_CORE_PATIENT => profile('Patient'), AU_BASE_PATIENT => profile('Patient') })
        entry = traces[AU_CORE_PATIENT].first

        assert_equal [AU_CORE_PATIENT, AU_BASE_PATIENT], traces.keys
        assert_equal({ read: true, matched_by: 'resource_type', elements_read: ['birthDate'] },
                     entry.slice(:read, :matched_by, :elements_read))
        assert_equal ['dob'], link_ids(entry)
      end

      def test_a_module_form_logs_the_assemble_context_names_it_reads
        form = questionnaire(
          extension: [assemble_context('ObsBodyWeightLatest'), assemble_context('age')],
          item: [item('weight', 'Weight', expression('initialExpression', '%ObsBodyWeightLatest.value.value'))]
        )

        assert_output(/Management Plan reads ObsBodyWeightLatest from the form it is assembled into/) do
          assert_empty trace(form)
        end
      end

      def test_a_query_for_a_type_without_a_group_is_untraced
        form = questionnaire(extension: [query_variable('Conditions', 'Condition?patient={{%patient.id}}')])

        assert_output(/untraced .* query Conditions/) { assert_empty trace(form) }
      end

      private

      def height_entry
        {
          source: 'query', **form_header,
          name: 'ObsBodyHeight', defined_at: 'root', query: HEIGHT_QUERY, matched_by: 'code',
          elements_read: ['value.value'],
          used_in: [{ link_id: 'height', text: 'Height', extension: 'initialExpression', reads: ['value.value'] }]
        }
      end

      # A read of the patient, so `%PatientRead` is the Patient, not a Bundle.
      def patient_read_form
        questionnaire(
          extension: [query_variable('PatientRead', 'Patient/{{%patient.id}}')],
          item: [item('dob', 'Date of birth', expression('initialExpression', '%PatientRead.birthDate'))]
        )
      end

      # `ObsBodyWeight` is defined on the `vitals` group and used by its child
      # `weight`. The sibling `other` reads it too, but is out of its scope.
      def weight_in_a_group_form
        weight = item('weight', 'Weight', expression('calculatedExpression', '%ObsBodyWeight.entry.resource.value'))
        other = item('other', 'Other', expression('initialExpression', '%ObsBodyWeight.entry.resource.status'))
        vitals = item('vitals', 'Vitals', query_variable('ObsBodyWeight', WEIGHT_QUERY), children: [weight])
        questionnaire(item: [vitals, other])
      end
    end
  end
end
