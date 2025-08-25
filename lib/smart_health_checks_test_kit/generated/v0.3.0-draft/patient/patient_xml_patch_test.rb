# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/patch_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class PatientXMLPatchTest < Inferno::Test
      include InfernoSuiteGenerator::PatchTest

      title '(SHALL) Server returns correct Patient resource from Patient patch interaction (XMLPatch)'
      description 'A server SHALL support the Patient patch interaction (XMLPatch).'

      id :smart_health_checks_v030_draft_patient_xml_patch_test

      def patch_data; end

      run do
        perform_xml_patch_test
      end
    end
  end
end
