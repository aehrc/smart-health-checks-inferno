# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/must_support_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV040
    class ShcWaistCircumferenceMustSupportTest < Inferno::Test
      include InfernoSuiteGenerator::MustSupportTest

      title 'All must support elements are provided in the Observation resources returned'
      description %(
        Smart Health Checks Responders SHALL be capable of populating all data elements as
        part of the query results as specified by the Smart Health Checks Server Capability
        Statement. This test will look through the Observation resources
        found previously for the following must support elements:

        * Observation.category
        * Observation.category:VSCat
        * Observation.category:VSCat.coding
        * Observation.category:VSCat.coding.code
        * Observation.category:VSCat.coding.system
        * Observation.code
        * Observation.code.coding:loincWaistCircumCode
        * Observation.code.coding:snomedWaistCircumCode
        * Observation.code.text
        * Observation.component
        * Observation.component.code
        * Observation.component.dataAbsentReason
        * Observation.component.value[x]
        * Observation.dataAbsentReason
        * Observation.effective[x]
        * Observation.status
        * Observation.subject
        * Observation.value[x]
        * Observation.value[x]:valueQuantity
        * Observation.value[x]:valueQuantity.code
        * Observation.value[x]:valueQuantity.system
        * Observation.value[x]:valueQuantity.unit
        * Observation.value[x]:valueQuantity.value
      )

      id :smart_health_checks_v040_shc_waist_circumference_must_support_test

      def resource_type
        'Observation'
      end

      def self.metadata
        @metadata ||= InfernoSuiteGenerator::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true))
      end

      def scratch_resources
        scratch[:shc_waist_circumference_resources] ||= {}
      end

      run do
        perform_must_support_test(all_scratch_resources)
      end
    end
  end
end
