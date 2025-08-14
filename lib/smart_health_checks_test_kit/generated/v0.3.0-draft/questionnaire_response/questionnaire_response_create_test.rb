# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/create_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class QuestionnaireResponseCreateTest < Inferno::Test
      include InfernoSuiteGenerator::CreateTest

      title '(SHALL) Server returns correct QuestionnaireResponse resource from QuestionnaireResponse create interaction'
      description 'A server SHALL support the QuestionnaireResponse create interaction.'

      input :shcquestionnaire_response_data,
            title: 'Smart Health Checks Questionnaire Response resource in JSON format',
            description: 'Smart Health Checks Questionnaire Response in JSON format to be sent to the server.',
            default: '',
            optional: false

      id :smart_health_checks_v030_draft_questionnaire_response_create_test

      def resource_type
        'QuestionnaireResponse'
      end

      def input_data
        'shcquestionnaire_response_data'
      end

      run do
        perform_create_test
      end
    end
  end
end
