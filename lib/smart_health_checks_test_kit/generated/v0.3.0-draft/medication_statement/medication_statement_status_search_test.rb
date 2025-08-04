# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/search_test'
require 'inferno_suite_generator/core/group_metadata'
require 'inferno_suite_generator/utils/helpers'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class MedicationStatementStatusSearchTest < Inferno::Test
      include InfernoSuiteGenerator::SearchTest

      title '(SHALL) Server returns valid results for MedicationStatement search by status'
      description %(
A server SHALL support searching by
status on the MedicationStatement resource. This test
will pass if resources are returned and match the search criteria. If
none are returned, the test is skipped.

[Smart Health Checks Server CapabilityStatement](https://smartforms.csiro.au/ig/CapabilityStatement/SHCHostFHIRServerCapabilityStatement)

      )

      id :smart_health_checks_v030_draft_medication_statement_status_search_test

      def self.properties
        @properties ||= InfernoSuiteGenerator::SearchTestProperties.new(
          resource_type: 'MedicationStatement',
          search_param_names: ['status'],
          includes: [{ 'parameter' => 'MedicationStatement:medication', 'target_resource' => '', 'paths' => '' }]
        )
      end

      def self.metadata
        @metadata ||= InfernoSuiteGenerator::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true))
      end

      def scratch_resources
        scratch[:medication_statement_resources] ||= {}
      end

      run do
        run_search_test
      end
    end
  end
end
