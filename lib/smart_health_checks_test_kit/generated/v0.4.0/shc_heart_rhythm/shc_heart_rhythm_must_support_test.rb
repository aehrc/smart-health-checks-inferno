# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/must_support_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV040
    class ShcHeartRhythmMustSupportTest < Inferno::Test
      include InfernoSuiteGenerator::MustSupportTest

      title 'All must support elements are provided in the Observation resources returned'
      description %(
        Smart Health Checks Responders SHALL be capable of populating all data elements as
        part of the query results as specified by the Smart Health Checks Server Capability
        Statement. This test will look through the Observation resources
        found previously for the following must support elements:

        * Observation.code.coding:loincHeartRhythmCode
        * Observation.code.coding:snomedHeartRhythmCode
        * Observation.code.text
        * Observation.effective[x]
        * Observation.status
        * Observation.subject
        * Observation.value[x].coding
      )

      id :smart_health_checks_v040_shc_heart_rhythm_must_support_test

      def resource_type
        'Observation'
      end

      def self.metadata
        @metadata ||= InfernoSuiteGenerator::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true))
      end

      def scratch_resources
        scratch[:shc_heart_rhythm_resources] ||= {}
      end

      run do
        perform_must_support_test(all_scratch_resources)
      end
    end
  end
end
