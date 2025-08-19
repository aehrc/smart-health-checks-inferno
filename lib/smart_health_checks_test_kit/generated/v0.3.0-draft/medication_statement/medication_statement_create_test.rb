# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/create_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class MedicationStatementCreateTest < Inferno::Test
      include InfernoSuiteGenerator::CreateTest

      title '(SHALL) Server returns correct MedicationStatement resource from MedicationStatement create interaction'
      description 'A server SHALL support the MedicationStatement create interaction.'

      input :shcmedication_statement_data,
            title: 'Smart Health Checks MedicationStatement resource in JSON format',
            description: 'Smart Health Checks MedicationStatement in JSON format to be sent to the server.',
            default: '{
  "meta": {
    "profile": [
      "https://smartforms.csiro.au/ig/StructureDefinition/SHCMedicationStatement"
    ]
  },
  "status": "text",
  "medicationCodeableConcept": {
    "coding": [
      {
        "system": "http://pbs.gov.au/code/item",
        "code": "13528B",
        "display": "simvastatin 10 mg tablet, 30"
      },
      {
        "system": "http://snomed.info/sct",
        "code": "21242011000036102",
        "display": "simvastatin (medicinal product)"
      }
    ]
  },
  "subject": {
    "reference": "http://example.com"
  },
  "resourceType": "MedicationStatement"
}',
            optional: false,
            type: 'textarea'

      id :smart_health_checks_v030_draft_medication_statement_create_test

      def resource_type
        'MedicationStatement'
      end

      def input_data
        'shcmedication_statement_data'
      end

      run do
        perform_create_test
      end
    end
  end
end
