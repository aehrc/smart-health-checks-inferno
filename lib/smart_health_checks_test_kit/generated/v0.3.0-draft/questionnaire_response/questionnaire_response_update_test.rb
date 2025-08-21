# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/update_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class QuestionnaireResponseUpdateTest < Inferno::Test
      include InfernoSuiteGenerator::UpdateTest

      title '(SHALL) Server returns correct QuestionnaireResponse resource from QuestionnaireResponse update interaction'
      description 'A server SHALL support the QuestionnaireResponse update interaction.'

      id :smart_health_checks_v030_draft_questionnaire_response_update_test

      def resource_type
        'QuestionnaireResponse'
      end

      run do
        perform_update_test
      end
    end
  end
end
