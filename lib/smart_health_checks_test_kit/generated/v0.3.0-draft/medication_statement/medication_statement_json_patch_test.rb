# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/patch_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class MedicationStatementJSONPatchTest < Inferno::Test
      include InfernoSuiteGenerator::PatchTest

      title '(SHALL) Server returns correct MedicationStatement resource from MedicationStatement patch interaction (JSONPatch)'
      description 'A server SHALL support the MedicationStatement patch interaction (JSONPatch).'

      id :smart_health_checks_v030_draft_medication_statement_json_patch_test

      def resource_type
        'MedicationStatement'
      end

      def patch_data
        [{ op: 'replace', path: '/status', value: 'completed' }]
      end

      run do
        perform_json_patch_test
      end
    end
  end
end
