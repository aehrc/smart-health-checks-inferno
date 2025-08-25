# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/patch_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class MedicationStatementXMLPatchTest < Inferno::Test
      include InfernoSuiteGenerator::PatchTest

      title '(SHALL) Server returns correct MedicationStatement resource from MedicationStatement patch interaction (XMLPatch)'
      description 'A server SHALL support the MedicationStatement patch interaction (XMLPatch).'

      id :smart_health_checks_v030_draft_medication_statement_xml_patch_test

      def patch_data
        { resource_type: 'MedicationStatement', id: 'chloramphenicol-pat-sf', patchset: { op: 'replace', path: '/MedicationStatement/status', value: 'completed' } }
      end

      run do
        perform_xml_patch_test
      end
    end
  end
end
