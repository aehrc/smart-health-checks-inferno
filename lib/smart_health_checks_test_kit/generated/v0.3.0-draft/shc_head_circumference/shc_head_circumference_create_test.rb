# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/create_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class ShcHeadCircumferenceCreateTest < Inferno::Test
      include InfernoSuiteGenerator::CreateTest

      title '(SHALL) Server returns correct Observation resource from Observation create interaction'
      description 'A server SHALL support the Observation create interaction.'

      id :smart_health_checks_v030_draft_shc_head_circumference_create_test

      def resource_type
        'Observation'
      end

      def input_data
        '{
  "meta": {
    "profile": [
      "https://smartforms.csiro.au/ig/StructureDefinition/SHCBloodPressure"
    ]
  },
  "status": "registered",
  "code": {
    "coding": [
      {
        "system": "http://example.com",
        "code": "example"
      }
    ]
  },
  "resourceType": "Observation"
}'
      end

      run do
        perform_create_test
      end
    end
  end
end
