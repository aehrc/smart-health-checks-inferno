# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/patch_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class MedicationStatementFHIRPathJSONPatchTest < Inferno::Test
      include InfernoSuiteGenerator::PatchTest

      title '(SHALL) Server returns correct MedicationStatement resource from MedicationStatement patch interaction (FHIRPath Patch in JSON format)'
      description 'A server SHALL support the MedicationStatement patch interaction (FHIRPath Patch in JSON format).'

      id :smart_health_checks_v030_draft_medication_statement_fhirpath_json_patch_test

      def self.demodata
        @demodata ||= InfernoSuiteGenerator::Generator::IGDemodata.new(
          YAML.load_file(File.join(File.dirname(__dir__), 'demodata.yml'), aliases: true)
        )
      end

      def resource_type
        'MedicationStatement'
      end

      run do
        perform_fhirpath_patch_json_test
      end
    end
  end
end
