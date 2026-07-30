# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/reference_resolution_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV040
    class QuestionnaireResponseReferenceResolutionTest < Inferno::Test
      include InfernoSuiteGenerator::ReferenceResolutionTest

      title 'MustSupport references within QuestionnaireResponse resources are valid'
      description %(
        This test will attempt to read external references provided within elements
        marked as 'MustSupport', if any are available.

        It verifies that at least one external reference for each MustSupport Reference element
        can be accessed by the test client, and conforms to corresponding Smart Health Checks profile.

        Elements which may provide external references include:

        * QuestionnaireResponse.author
        * QuestionnaireResponse.encounter
        * QuestionnaireResponse.item.item.item.answer.value[x]
        * QuestionnaireResponse.item.item.item.item.answer.value[x]
        * QuestionnaireResponse.item.item.item.item.item.answer.value[x]
        * QuestionnaireResponse.item.item.item.item.item.item.answer.value[x]
        * QuestionnaireResponse.subject
      )

      id :smart_health_checks_v040_questionnaire_response_reference_resolution_test

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
        perform_reference_resolution_test(
          scratch_resources[:all],
          {},
          %w[Encounter Patient Practitioner QuestionnaireResponse]
        )
      end
    end
  end
end
