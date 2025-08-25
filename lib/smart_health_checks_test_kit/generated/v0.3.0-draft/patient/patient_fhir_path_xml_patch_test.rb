# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/patch_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class PatientFHIRPathXMLPatchTest < Inferno::Test
      include InfernoSuiteGenerator::PatchTest

      title '(SHALL) Server returns correct Patient resource from Patient patch interaction (FHIRPath Patch in XML format)'
      description 'A server SHALL support the Patient patch interaction (FHIRPath Patch in XML format).'

      id :smart_health_checks_v030_draft_patient_fhirpath_xml_patch_test

      def patch_data; end

      run do
        perform_fhirpath_patch_xml_text
      end
    end
  end
end
