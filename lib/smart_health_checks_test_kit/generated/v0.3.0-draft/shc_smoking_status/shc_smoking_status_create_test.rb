# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/create_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class ShcSmokingStatusCreateTest < Inferno::Test
      include InfernoSuiteGenerator::CreateTest

      title '(SHALL) Server returns correct Observation resource from Observation create interaction'
      description 'A server SHALL support the Observation create interaction.'

      input :shcsmoking_status_data,
            title: 'Smart Health Checks Smoking Status resource in JSON format',
            description: 'Smart Health Checks Smoking Status in JSON format to be sent to the server.',
            default: '',
            optional: false

      id :smart_health_checks_v030_draft_shc_smoking_status_create_test

      def resource_type
        'Observation'
      end

      def input_data
        'shcsmoking_status_data'
      end

      run do
        perform_create_test
      end
    end
  end
end
