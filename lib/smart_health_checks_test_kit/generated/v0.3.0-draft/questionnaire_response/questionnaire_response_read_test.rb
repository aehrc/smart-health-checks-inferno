# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/read_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class QuestionnaireResponseReadTest < Inferno::Test
      include InfernoSuiteGenerator::ReadTest

      title '(SHALL) Server returns correct QuestionnaireResponse resource from QuestionnaireResponse read interaction'
      description 'A server SHALL support the QuestionnaireResponse read interaction.'

      id :smart_health_checks_v030_draft_questionnaire_response_read_test

      def resource_type
        'QuestionnaireResponse'
      end

      def scratch_resources
        scratch[:questionnaire_response_resources] ||= {}
      end

      run do
        perform_read_test(all_scratch_resources)
      end
    end
  end
end
