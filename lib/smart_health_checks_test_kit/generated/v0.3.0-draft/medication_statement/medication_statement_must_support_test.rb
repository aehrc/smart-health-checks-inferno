# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/must_support_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class MedicationStatementMustSupportTest < Inferno::Test
      include InfernoSuiteGenerator::MustSupportTest

      title 'All must support elements are provided in the MedicationStatement resources returned'
      description %(
        Smart Health Checks Responders SHALL be capable of populating all data elements as
        part of the query results as specified by the Smart Health Checks Server Capability
        Statement. This test will look through the MedicationStatement resources
        found previously for the following must support elements:

        * MedicationStatement.dateAsserted
        * MedicationStatement.dosage
        * MedicationStatement.dosage.text
        * MedicationStatement.effective[x]
        * MedicationStatement.id
        * MedicationStatement.medication[x]
        * MedicationStatement.medication[x]:medicationCodeableConcept
        * MedicationStatement.medication[x]:medicationCodeableConcept.text
        * MedicationStatement.medication[x]:medicationReference
        * MedicationStatement.note
        * MedicationStatement.note.text
        * MedicationStatement.reasonCode
        * MedicationStatement.reasonReference
        * MedicationStatement.status
        * MedicationStatement.subject
      )

      id :smart_health_checks_v030_draft_medication_statement_must_support_test

      def resource_type
        'MedicationStatement'
      end

      def self.metadata
        @metadata ||= InfernoSuiteGenerator::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true))
      end

      def scratch_resources
        scratch[:medication_statement_resources] ||= {}
      end

      run do
        perform_must_support_test(all_scratch_resources)
      end
    end
  end
end
