# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/create_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class ShcBodyWeightCreateTest < Inferno::Test
      include InfernoSuiteGenerator::CreateTest

      title '(SHALL) Server returns correct Observation resource from Observation create interaction'
      description 'A server SHALL support the Observation create interaction.'

      input :shcbody_weight_data,
            title: 'Smart Health Checks Body Weight resource in JSON format',
            description: 'Smart Health Checks Body Weight in JSON format to be sent to the server.',
            default: '',
            optional: false,
            type: 'textarea'

      id :smart_health_checks_v030_draft_shc_body_weight_create_test

      def resource_type
        'Observation'
      end

      def input_data
        'shcbody_weight_data'
      end

      run do
        perform_create_test
      end
    end
  end
end
