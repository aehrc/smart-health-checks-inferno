# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/create_test'
require 'inferno_suite_generator/utils/references_keeper'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class ShcHeadCircumferenceCreateTest < Inferno::Test
      include InfernoSuiteGenerator::CreateTest

      title '(SHALL) Server returns correct Observation resource from Observation create interaction'
      description 'A server SHALL support the Observation create interaction.'

      input :references_mapping_input,
            title: 'References Mapping',
            description: 'Mapping of references to the create resource. Format: ["Patient/patient_id1", "Medication/medication_id1"]',
            type: 'textarea',
            optional: true

      id :smart_health_checks_v030_draft_shc_head_circumference_create_test

      def self.demodata
        @demodata ||= InfernoSuiteGenerator::Generator::IGDemodata.new(
          YAML.load_file(File.join(File.dirname(__dir__), 'demodata.yml'), aliases: true)
        )
      end

      def self.metadata
        @metadata ||= InfernoSuiteGenerator::Generator::GroupMetadata.new(
          YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true)
        )
      end

      def resource_type
        'Observation'
      end

      def references_keeper
        @rerefences_keeper = InfernoSuiteGenerator::ReferencesKeeper.get_or_create_instance(url)
      end

      def resource_to_create_filter
        nil
      end

      run do
        perform_create_test
      end
    end
  end
end
