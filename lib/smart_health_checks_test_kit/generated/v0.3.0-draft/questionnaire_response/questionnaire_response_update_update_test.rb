# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/update_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class QuestionnaireResponseUPDATEUpdateTest < Inferno::Test
      include InfernoSuiteGenerator::UpdateTest

      title '(SHALL) Server returns correct QuestionnaireResponse resource from QuestionnaireResponse update interaction (Update).'
      description 'A server SHALL support the QuestionnaireResponse update interaction (Update).'

      id :smart_health_checks_v030_draft_questionnaire_response_update_update_test

      def resource_type
        'QuestionnaireResponse'
      end

      def self.demodata
        @demodata ||= InfernoSuiteGenerator::Generator::IGDemodata.new(
          YAML.load_file(File.join(File.dirname(__dir__), 'demodata.yml'), aliases: true)
        )
      end

      def self.metadata
        @metadata ||= InfernoSuiteGenerator::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true))
      end

      def resource_to_create_filter
        nil
      end

      run do
        perform_update_test
      end
    end
  end
end
