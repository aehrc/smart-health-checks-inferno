# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/create_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class ShcConditionCreateTest < Inferno::Test
      include InfernoSuiteGenerator::CreateTest

      title '(SHALL) Server returns correct Condition resource from Condition create interaction'
      description 'A server SHALL support the Condition create interaction.'

      id :smart_health_checks_v030_draft_shc_condition_create_test

      def resource_type
        'Condition'
      end

      def input_data
        '{
  "meta": {
    "profile": [
      "https://smartforms.csiro.au/ig/StructureDefinition/SHCCondition"
    ]
  },
  "subject": {
    "reference": "http://example.com"
  },
  "resourceType": "Condition"
}'
      end

      run do
        perform_create_test
      end
    end
  end
end
