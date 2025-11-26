# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/create_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV040_CI_BUILD
    class MedicationStatementCreateTest < Inferno::Test
      include InfernoSuiteGenerator::CreateTest

      title '(SHALL) Server returns correct MedicationStatement resource from MedicationStatement create interaction'
      description 'A server SHALL support the MedicationStatement create interaction.'

      id :smart_health_checks_v040_ci_build_medication_statement_create_test

      def self.demodata
        @demodata ||= InfernoSuiteGenerator::Generator::IGDemodata.new(
          YAML.load_file(File.join(File.dirname(__dir__), 'demodata.yml'), aliases: true)
        )
      end

      def resource_type
        'MedicationStatement'
      end

      run do
        perform_create_test
      end
    end
  end
end
