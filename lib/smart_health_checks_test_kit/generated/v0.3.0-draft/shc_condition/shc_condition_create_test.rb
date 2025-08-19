# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/create_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class ShcConditionCreateTest < Inferno::Test
      include InfernoSuiteGenerator::CreateTest

      title '(SHALL) Server returns correct Condition resource from Condition create interaction'
      description 'A server SHALL support the Condition create interaction.'

      input :shccondition_data,
            title: 'Smart Health Checks Condition resource in JSON format',
            description: 'Smart Health Checks Condition in JSON format to be sent to the server.',
            default: '{
  "meta": {
    "profile": [
      "https://smartforms.csiro.au/ig/StructureDefinition/SHCCondition"
    ]
  },
  "subject": {
    "reference": "http://example.com"
  },
  "resourceType": "Condition"
}',
            optional: false,
            type: 'textarea'

      id :smart_health_checks_v030_draft_shc_condition_create_test

      def resource_type
        'Condition'
      end

      def input_data
        'shccondition_data'
      end

      run do
        perform_create_test
      end
    end
  end
end
