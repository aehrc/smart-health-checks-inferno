# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/create_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class QuestionnaireResponseCreateTest < Inferno::Test
      include InfernoSuiteGenerator::CreateTest

      title '(SHALL) Server returns correct QuestionnaireResponse resource from QuestionnaireResponse create interaction'
      description 'A server SHALL support the QuestionnaireResponse create interaction.'

      id :smart_health_checks_v030_draft_questionnaire_response_create_test

      def self.demodata
        @demodata ||= InfernoSuiteGenerator::Generator::IGDemodata.new(
          YAML.load_file(File.join(File.dirname(__dir__), 'demodata.yml'), aliases: true)
        )
      end

      def resource_type
        'QuestionnaireResponse'
      end

      def input_data
        '{
  "meta": {
    "profile": [
      "https://smartforms.csiro.au/ig/StructureDefinition/SHCQuestionnaireResponse"
    ]
  },
  "status": "text",
  "resourceType": "QuestionnaireResponse"
}'
      end

      run do
        perform_create_test
      end
    end
  end
end
