# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/create_test'
require 'inferno_suite_generator/utils/references_keeper'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class MedicationStatementCreateTest < Inferno::Test
      include InfernoSuiteGenerator::CreateTest

      title '(SHALL) Server returns correct MedicationStatement resource from MedicationStatement create interaction'
      description 'A server SHALL support the MedicationStatement create interaction.'

      id :smart_health_checks_v030_draft_medication_statement_create_test

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
        'MedicationStatement'
      end

      def references_keeper
        @references_keeper ||= InfernoSuiteGenerator::ReferencesKeeper.instance
      end

      run do
        perform_create_test
      end
    end
  end
end
