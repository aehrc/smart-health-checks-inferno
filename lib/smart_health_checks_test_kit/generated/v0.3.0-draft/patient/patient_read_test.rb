# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/read_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class PatientReadTest < Inferno::Test
      include InfernoSuiteGenerator::ReadTest

      title '(SHALL) Server returns correct Patient resource from Patient read interaction'
      description 'A server SHALL support the Patient read interaction.'

      input :patient_ids,
            title: 'Patient IDs',
            description: 'Comma separated list of patient IDs that in sum contain all MUST SUPPORT elements',
            default: '',
            optional: true

      id :smart_health_checks_v030_draft_patient_read_test

      def resource_type
        'Patient'
      end

      def scratch_resources
        scratch[:patient_resources] ||= {}
      end

      run do
        perform_read_test(all_scratch_resources)
      end
    end
  end
end
