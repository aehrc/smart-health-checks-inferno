# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/create_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class ImmunizationCreateTest < Inferno::Test
      include InfernoSuiteGenerator::CreateTest

      title '(SHALL) Server returns correct Immunization resource from Immunization create interaction'
      description 'A server SHALL support the Immunization create interaction.'

      id :smart_health_checks_v030_draft_immunization_create_test

      def resource_type
        'Immunization'
      end

      def input_data
        '{
  "meta": {
    "profile": [
      "https://smartforms.csiro.au/ig/StructureDefinition/SHCImmunization"
    ]
  },
  "status": "completed",
  "vaccineCode": {
    "coding": [
      {
        "system": "http://example.com",
        "code": "example"
      }
    ]
  },
  "patient": {
    "reference": "Patient/pat-sf"
  },
  "occurrenceString": "example",
  "resourceType": "Immunization"
}'
      end

      run do
        perform_create_test
      end
    end
  end
end
