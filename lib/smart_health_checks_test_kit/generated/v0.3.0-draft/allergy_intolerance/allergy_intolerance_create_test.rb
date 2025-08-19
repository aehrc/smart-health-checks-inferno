# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/create_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class AllergyIntoleranceCreateTest < Inferno::Test
      include InfernoSuiteGenerator::CreateTest

      title '(SHALL) Server returns correct AllergyIntolerance resource from AllergyIntolerance create interaction'
      description 'A server SHALL support the AllergyIntolerance create interaction.'

      input :shcallergy_intolerance_data,
            title: 'Smart Health Checks AllergyIntolerance resource in JSON format',
            description: 'Smart Health Checks AllergyIntolerance in JSON format to be sent to the server.',
            default: '{
  "meta": {
    "profile": [
      "https://smartforms.csiro.au/ig/StructureDefinition/SHCAllergyIntolerance"
    ]
  },
  "clinicalStatus": {
    "coding": [
      {
        "system": "http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical",
        "code": "active",
        "display": "Active"
      }
    ]
  },
  "patient": {
    "reference": "http://example.com"
  },
  "reaction": [
    {
      "manifestation": [
        {
          "coding": [
            {
              "system": "http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical",
              "code": "active",
              "display": "Active"
            }
          ]
        }
      ],
      "severity": "mild"
    }
  ],
  "resourceType": "AllergyIntolerance"
}',
            optional: false,
            type: 'textarea'

      id :smart_health_checks_v030_draft_allergy_intolerance_create_test

      def resource_type
        'AllergyIntolerance'
      end

      def input_data
        'shcallergy_intolerance_data'
      end

      run do
        perform_create_test
      end
    end
  end
end
