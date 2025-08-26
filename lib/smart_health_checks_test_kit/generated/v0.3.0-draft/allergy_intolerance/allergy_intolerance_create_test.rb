# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/create_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class AllergyIntoleranceCreateTest < Inferno::Test
      include InfernoSuiteGenerator::CreateTest

      title '(SHALL) Server returns correct AllergyIntolerance resource from AllergyIntolerance create interaction'
      description 'A server SHALL support the AllergyIntolerance create interaction.'

      id :smart_health_checks_v030_draft_allergy_intolerance_create_test

      def self.demodata
        @demodata ||= InfernoSuiteGenerator::Generator::IGDemodata.new(
          YAML.load_file(File.join(File.dirname(__dir__), 'demodata.yml'), aliases: true)
        )
      end

      def resource_type
        'AllergyIntolerance'
      end

      def input_data
        '{
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
}'
      end

      run do
        perform_create_test
      end
    end
  end
end
