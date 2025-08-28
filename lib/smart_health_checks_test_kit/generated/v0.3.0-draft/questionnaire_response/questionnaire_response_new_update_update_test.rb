# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/update_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class QuestionnaireResponseNEW_UPDATEUpdateTest < Inferno::Test
      include InfernoSuiteGenerator::UpdateTest

      title '(SHALL) Server returns correct QuestionnaireResponse resource from QuestionnaireResponse update interaction (UpdateNew).'
      description 'A server SHALL support the QuestionnaireResponse update interaction (UpdateNew).'

      id :smart_health_checks_v030_draft_questionnaire_response_update_new_update_test

      def resource_type
        'QuestionnaireResponse'
      end

      run do
        perform_update_new_test
      end
    end
  end
end
