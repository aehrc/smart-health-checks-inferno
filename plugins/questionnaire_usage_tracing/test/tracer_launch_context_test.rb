# frozen_string_literal: true

require_relative 'support'

module InfernoSuitePlugins
  module QuestionnaireUsageTracing
    # Verifies `Tracer` traces `launchContext` resources and the elements the
    # items read from them.
    class TracerLaunchContextTest < Minitest::Test
      include TracerFixtures

      AU_CORE_PRACTITIONER = 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-practitioner'

      def test_an_item_reads_an_element_of_the_launch_patient
        form = questionnaire(extension: [launch_context('patient', 'Patient')],
                             item: [item('dob', 'Date of birth',
                                         expression('initialExpression', '%patient.birthDate.toString()'))])

        assert_equal [{
          source: 'launch_context', **form_header,
          name: 'patient', defined_at: 'root', matched_by: 'resource_type', elements_read: ['birthDate'],
          used_in: [{ link_id: 'dob', text: 'Date of birth', extension: 'initialExpression',
                      reads: ['birthDate'] }]
        }], trace(form, profiles: patient_profiles)[AU_CORE_PATIENT]
      end

      def test_every_patient_group_gets_the_entry
        form = questionnaire(extension: [launch_context('patient', 'Patient')])

        assert_equal [AU_CORE_PATIENT, AU_BASE_PATIENT], trace(form, profiles: patient_profiles).keys
      end

      def test_an_alias_of_the_launch_patient
        recorded_sex = "%patient.extension.where(url = '#{RECORDED_SEX_URL}')"
        form = questionnaire(extension: [launch_context('patient', 'Patient'),
                                         fhirpath_variable('RecordedSex', recorded_sex)],
                             item: [item('sex', 'Sex', expression('initialExpression', '%RecordedSex.value.code'))])
        entry = trace(form, profiles: patient_profiles)[AU_CORE_PATIENT].first

        assert_equal ["extension[url=#{RECORDED_SEX_URL}]", "extension[url=#{RECORDED_SEX_URL}].value.code"],
                     entry[:elements_read]
        assert_equal ['RecordedSex'], vias(entry)
      end

      def test_one_entry_per_type_of_the_launch_context
        form = questionnaire(extension: [launch_context('user', 'Practitioner', 'Patient', value_id: true)],
                             item: [item('author', 'Author', expression('initialExpression', '%user.name.text'))])
        traces = trace(form, profiles: patient_profiles.merge(AU_CORE_PRACTITIONER => profile('Practitioner')))

        assert_equal [AU_CORE_PRACTITIONER, AU_CORE_PATIENT, AU_BASE_PATIENT], traces.keys
        assert_equal ['name.text'], traces[AU_CORE_PRACTITIONER].first[:elements_read]
      end

      def test_a_chain_that_picks_one_type_counts_for_that_type_only
        fhirpath = "%user.where(resourceType = 'Practitioner').qualification.code"
        form = questionnaire(extension: [launch_context('user', 'Practitioner', 'Patient')],
                             item: [item('qualification', 'Qualification', expression('initialExpression', fhirpath))])
        traces = trace(form, profiles: patient_profiles.merge(AU_CORE_PRACTITIONER => profile('Practitioner')))

        assert_equal ['qualification.code'], traces[AU_CORE_PRACTITIONER].first[:elements_read]
        assert_empty traces[AU_CORE_PATIENT].first[:used_in]
      end

      def test_an_expression_on_the_root_is_a_usage
        form = questionnaire(extension: [launch_context('patient', 'Patient'),
                                         expression('itemExtractionContext', '%patient.name')])
        entry = trace(form, profiles: patient_profiles)[AU_CORE_PATIENT].first

        assert_equal [{ extension: 'itemExtractionContext', reads: ['name'] }], entry[:used_in]
      end

      def test_a_form_without_a_url_is_named_by_its_id
        form = questionnaire(extension: [launch_context('patient', 'Patient')]).except('url').merge('id' => 'intake')
        entry = trace(form, profiles: patient_profiles)[AU_CORE_PATIENT].first

        assert_equal 'intake', entry[:questionnaire_id]
        refute entry.key?(:questionnaire_url)
      end

      def test_a_launch_context_without_a_group_for_its_type_is_untraced
        form = questionnaire(extension: [launch_context('encounter', 'Encounter')])

        assert_output(/untraced .* launch context encounter: no group for Encounter/) do
          assert_empty trace(form, profiles: patient_profiles)
        end
      end

      private

      def patient_profiles
        { AU_CORE_PATIENT => profile('Patient'), AU_BASE_PATIENT => profile('Patient') }
      end
    end
  end
end
