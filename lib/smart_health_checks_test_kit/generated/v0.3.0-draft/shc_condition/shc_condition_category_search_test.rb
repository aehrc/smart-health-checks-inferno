# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/search_test'
require 'inferno_suite_generator/core/group_metadata'
require 'inferno_suite_generator/utils/helpers'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class ShcConditionCategorySearchTest < Inferno::Test
      include InfernoSuiteGenerator::SearchTest

      title '(SHALL) Server returns valid results for Condition search by category'
      description %(
A server SHALL support searching by
category on the Condition resource. This test
will pass if resources are returned and match the search criteria. If
none are returned, the test is skipped.

[Smart Health Checks Server CapabilityStatement](https://smartforms.csiro.au/ig/CapabilityStatement/SHCHostFHIRServerCapabilityStatement)

      )

      id :smart_health_checks_v030_draft_shc_condition_category_search_test

      def self.properties
        @properties ||= InfernoSuiteGenerator::SearchTestProperties.new(
          resource_type: 'Condition',
          search_param_names: ['category'],
          token_search_params: ['category']
        )
      end

      def self.metadata
        @metadata ||= InfernoSuiteGenerator::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true))
      end

      def scratch_resources
        scratch[:shc_condition_resources] ||= {}
      end

      run do
        run_search_test
      end
    end
  end
end
