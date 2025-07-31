# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/must_support_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class ImmunizationMustSupportTest < Inferno::Test
      include InfernoSuiteGenerator::MustSupportTest

      title 'All must support elements are provided in the Immunization resources returned'
      description %(
        Smart Health Checks Responders SHALL be capable of populating all data elements as
        part of the query results as specified by the Smart Health Checks Server Capability
        Statement. This test will look through the Immunization resources
        found previously for the following must support elements:

        * Immunization.lotNumber
        * Immunization.note
        * Immunization.note.text
        * Immunization.occurrence[x]
        * Immunization.occurrence[x]:occurrenceDateTime
        * Immunization.patient
        * Immunization.primarySource
        * Immunization.status
        * Immunization.vaccineCode
      )

      id :smart_health_checks_v030_draft_immunization_must_support_test

      def resource_type
        'Immunization'
      end

      def self.metadata
        @metadata ||= InfernoSuiteGenerator::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true))
      end

      def scratch_resources
        scratch[:immunization_resources] ||= {}
      end

      run do
        perform_must_support_test(all_scratch_resources)
      end
    end
  end
end
