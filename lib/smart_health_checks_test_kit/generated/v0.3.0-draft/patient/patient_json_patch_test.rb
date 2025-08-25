# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/patch_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class PatientJSONPatchTest < Inferno::Test
      include InfernoSuiteGenerator::PatchTest

      title '(SHALL) Server returns correct Patient resource from Patient patch interaction (JSONPatch)'
      description 'A server SHALL support the Patient patch interaction (JSONPatch).'

      input :patient_ids,
            title: 'Patient IDs',
            description: 'Comma separated list of patient',
            default: '',
            optional: false

      id :smart_health_checks_v030_draft_patient_json_patch_test

      def resource_type
        'Patient'
      end

      def patch_data; end

      run do
        perform_json_patch_test
      end
    end
  end
end
