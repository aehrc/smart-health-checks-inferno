# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/read_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class EncounterReadTest < Inferno::Test
      include InfernoSuiteGenerator::ReadTest

      title '(SHALL) Server returns correct Encounter resource from Encounter read interaction'
      description 'A server SHALL support the Encounter read interaction.'

      input :encounter_ids,
            title: 'Encounter IDs',
            description: 'Comma separated list of encounter IDs that in sum contain all MUST SUPPORT elements',
            default: '',
            optional: true

      id :smart_health_checks_v030_draft_encounter_read_test

      def self.demodata
        @demodata ||= InfernoSuiteGenerator::Generator::IGDemodata.new(
          YAML.load_file(File.join(File.dirname(__dir__), 'demodata.yml'), aliases: true)
        )
      end

      def resource_type
        'Encounter'
      end

      def scratch_resources
        scratch[:encounter_resources] ||= {}
      end

      run do
        perform_read_test(scratch.dig(:references, 'Encounter'))
      end
    end
  end
end
