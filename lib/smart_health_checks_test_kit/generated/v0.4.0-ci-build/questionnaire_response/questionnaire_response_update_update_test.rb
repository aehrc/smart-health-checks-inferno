# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/update_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV040_CI_BUILD
    class QuestionnaireResponseUPDATEUpdateTest < Inferno::Test
      include InfernoSuiteGenerator::UpdateTest

      title '(SHALL) Server returns correct QuestionnaireResponse resource from QuestionnaireResponse update interaction (Update).'
      description 'A server SHALL support the QuestionnaireResponse update interaction (Update).'

      id :smart_health_checks_v040_ci_build_questionnaire_response_update_update_test

      def resource_type
        'QuestionnaireResponse'
      end

      run do
        perform_update_test
      end
    end
  end
end
