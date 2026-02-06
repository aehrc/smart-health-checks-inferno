# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/create_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV040
    class ShcConditionCreateTest < Inferno::Test
      include InfernoSuiteGenerator::CreateTest

      title '(SHALL) Server returns correct Condition resource from Condition create interaction'
      description 'A server SHALL support the Condition create interaction.'

      id :smart_health_checks_v040_shc_condition_create_test

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
        'Condition'
      end

      run do
        perform_create_test
      end
    end
  end
end
