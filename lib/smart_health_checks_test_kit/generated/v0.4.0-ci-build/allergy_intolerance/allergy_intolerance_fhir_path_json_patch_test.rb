# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/patch_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV040_CI_BUILD
    class AllergyIntoleranceFHIRPathJSONPatchTest < Inferno::Test
      include InfernoSuiteGenerator::PatchTest

      title '(SHALL) Server returns correct AllergyIntolerance resource from AllergyIntolerance patch interaction (FHIRPath Patch in JSON format)'
      description 'A server SHALL support the AllergyIntolerance patch interaction (FHIRPath Patch in JSON format).'

      id :smart_health_checks_v040_ci_build_allergy_intolerance_fhirpath_json_patch_test

      def self.demodata
        @demodata ||= InfernoSuiteGenerator::Generator::IGDemodata.new(
          YAML.load_file(File.join(File.dirname(__dir__), 'demodata.yml'), aliases: true)
        )
      end

      def self.metadata
        @metadata ||= InfernoSuiteGenerator::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true))
      end

      def resource_type
        'AllergyIntolerance'
      end

      run do
        perform_fhirpath_patch_json_test
      end
    end
  end
end
