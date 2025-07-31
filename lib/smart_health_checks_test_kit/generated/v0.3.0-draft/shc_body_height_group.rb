# frozen_string_literal: true

require_relative 'shc_body_height/shc_body_height_validation_test'
require_relative 'shc_body_height/shc_body_height_must_support_test'
require_relative 'shc_body_height/shc_body_height_reference_resolution_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class ShcBodyHeightGroup < Inferno::TestGroup
      title 'Observation Body Height Tests'
      short_description 'Verify support for the server capabilities required by the Smart Health Checks Body Height.'
      description %(
  # Background

The Smart Health Checks Observation Body Height sequence verifies that the system under test is
able to provide correct responses for Observation queries. These queries
must contain resources conforming to the Smart Health Checks Body Height as
specified in the Smart Health Checks v0.3.0-draft Implementation Guide.

# Testing Methodology


## Must Support
Each profile contains elements marked as "must support". This test
sequence expects to see each of these elements at least once. If at
least one cannot be found, the test will fail. The test will look
through the Observation resources found in the first test for these
elements.

## Profile Validation
Each resource returned from the first search is expected to conform to
the [Smart Health Checks Body Height](https://smartforms.csiro.au/ig/StructureDefinition/SHCBodyHeight). Each element is checked against
teminology binding and cardinality requirements.

Elements with a required binding are validated against their bound
ValueSet. If the code/system in the element is not part of the ValueSet,
then the test will fail.

## Reference Validation
At least one instance of each external reference in elements marked as
"must support" within the resources provided by the system must resolve.
The test will attempt to read each reference found and will fail if no
read succeeds.

      )

      id :smart_health_checks_v030_draft_shc_body_height
      run_as_group

      def self.metadata
        @metadata ||= InfernoSuiteGenerator::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'shc_body_height', 'metadata.yml'), aliases: true))
      end

      test from: :smart_health_checks_v030_draft_shc_body_height_validation_test
      test from: :smart_health_checks_v030_draft_shc_body_height_must_support_test
      test from: :smart_health_checks_v030_draft_shc_body_height_reference_resolution_test
    end
  end
end
