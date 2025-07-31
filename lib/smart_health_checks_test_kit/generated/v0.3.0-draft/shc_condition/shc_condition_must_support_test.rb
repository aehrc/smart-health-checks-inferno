# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/must_support_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class ShcConditionMustSupportTest < Inferno::Test
      include InfernoSuiteGenerator::MustSupportTest

      title 'All must support elements are provided in the Condition resources returned'
      description %(
        Smart Health Checks Responders SHALL be capable of populating all data elements as
        part of the query results as specified by the Smart Health Checks Server Capability
        Statement. This test will look through the Condition resources
        found previously for the following must support elements:

        * Condition.abatement[x]
        * Condition.abatement[x]:abatementDateTime
        * Condition.category
        * Condition.clinicalStatus
        * Condition.code
        * Condition.id
        * Condition.note
        * Condition.note.text
        * Condition.onset[x]
        * Condition.onset[x]:onsetDateTime
        * Condition.severity
        * Condition.subject
        * Condition.verificationStatus
      )

      id :smart_health_checks_v030_draft_shc_condition_must_support_test

      def resource_type
        'Condition'
      end

      def self.metadata
        @metadata ||= InfernoSuiteGenerator::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true))
      end

      def scratch_resources
        scratch[:shc_condition_resources] ||= {}
      end

      run do
        perform_must_support_test(all_scratch_resources)
      end
    end
  end
end
