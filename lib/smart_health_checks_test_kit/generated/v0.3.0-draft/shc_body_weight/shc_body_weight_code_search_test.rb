# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/search_test'
require 'inferno_suite_generator/core/group_metadata'
require 'inferno_suite_generator/utils/helpers'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class ShcBodyWeightCodeSearchTest < Inferno::Test
      include InfernoSuiteGenerator::SearchTest

      title '(SHALL) Server returns valid results for Observation search by code'
      description %(
A server SHALL support searching by
code on the Observation resource. This test
will pass if resources are returned and match the search criteria. If
none are returned, the test is skipped.

[Smart Health Checks Server CapabilityStatement](https://smartforms.csiro.au/ig/CapabilityStatement/SHCHostFHIRServerCapabilityStatement)

      )

      id :smart_health_checks_v030_draft_shc_body_weight_code_search_test

      def self.properties
        @properties ||= InfernoSuiteGenerator::SearchTestProperties.new(
          resource_type: 'Observation',
          search_param_names: ['code'],
          token_search_params: ['code']
        )
      end

      def self.metadata
        @metadata ||= InfernoSuiteGenerator::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true))
      end

      def scratch_resources
        scratch[:shc_body_weight_resources] ||= {}
      end

      run do
        run_search_test
      end
    end
  end
end
