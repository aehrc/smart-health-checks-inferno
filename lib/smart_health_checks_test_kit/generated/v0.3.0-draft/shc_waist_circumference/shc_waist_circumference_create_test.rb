# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/create_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class ShcWaistCircumferenceCreateTest < Inferno::Test
      include InfernoSuiteGenerator::CreateTest

      title '(SHALL) Server returns correct Observation resource from Observation create interaction'
      description 'A server SHALL support the Observation create interaction.'

      input :shcwaist_circumference_data,
            title: 'Smart Health Checks Waist Circumference resource in JSON format',
            description: 'Smart Health Checks Waist Circumference in JSON format to be sent to the server.',
            default: '{
  "id": "3014128d-fa6c-4665-928a-035e3ff8fd9e",
  "meta": {
    "profile": [
      "https://smartforms.csiro.au/ig/StructureDefinition/SHCBloodPressure"
    ]
  },
  "status": "text",
  "code": {
    "coding": [
      {
        "system": "http://example.com",
        "code": "example"
      }
    ]
  },
  "resourceType": "Observation"
}',
            optional: false,
            type: 'textarea'

      id :smart_health_checks_v030_draft_shc_waist_circumference_create_test

      def resource_type
        'Observation'
      end

      def input_data
        'shcwaist_circumference_data'
      end

      run do
        perform_create_test
      end
    end
  end
end
