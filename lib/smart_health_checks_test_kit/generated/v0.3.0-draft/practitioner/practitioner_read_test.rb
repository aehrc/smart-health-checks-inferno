# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/read_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class PractitionerReadTest < Inferno::Test
      include InfernoSuiteGenerator::ReadTest

      title '(SHALL) Server returns correct Practitioner resource from Practitioner read interaction'
      description 'A server SHALL support the Practitioner read interaction.'

      id :smart_health_checks_v030_draft_practitioner_read_test

      def resource_type
        'Practitioner'
      end

      def scratch_resources
        scratch[:practitioner_resources] ||= {}
      end

      run do
        perform_read_test(scratch.dig(:references, 'Practitioner'))
      end
    end
  end
end
