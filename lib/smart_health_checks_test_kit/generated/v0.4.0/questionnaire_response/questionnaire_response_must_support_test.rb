# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/must_support_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV040
    class QuestionnaireResponseMustSupportTest < Inferno::Test
      include InfernoSuiteGenerator::MustSupportTest

      title 'All must support elements are provided in the QuestionnaireResponse resources returned'
      description %(
        Smart Health Checks Responders SHALL be capable of populating all data elements as
        part of the query results as specified by the Smart Health Checks Server Capability
        Statement. This test will look through the QuestionnaireResponse resources
        found previously for the following must support elements:

        * QuestionnaireResponse.author
        * QuestionnaireResponse.authored
        * QuestionnaireResponse.encounter
        * QuestionnaireResponse.id
        * QuestionnaireResponse.identifier
        * QuestionnaireResponse.item
        * QuestionnaireResponse.item.answer
        * QuestionnaireResponse.item.answer.item
        * QuestionnaireResponse.item.answer.value[x]
        * QuestionnaireResponse.item.item
        * QuestionnaireResponse.item.linkId
        * QuestionnaireResponse.item.text
        * QuestionnaireResponse.questionnaire
        * QuestionnaireResponse.questionnaire.extension:questionnaireDisplay
        * QuestionnaireResponse.status
        * QuestionnaireResponse.subject
        * QuestionnaireResponse.text
      )

      id :smart_health_checks_v040_questionnaire_response_must_support_test

      def resource_type
        'QuestionnaireResponse'
      end

      def self.metadata
        @metadata ||= InfernoSuiteGenerator::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true))
      end

      def scratch_resources
        scratch[:questionnaire_response_resources] ||= {}
      end

      run do
        perform_must_support_test(all_scratch_resources)
      end
    end
  end
end
