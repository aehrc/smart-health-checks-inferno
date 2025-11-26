# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/validation_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class PractitionerValidationTest < Inferno::Test
      include InfernoSuiteGenerator::ValidationTest

      id :smart_health_checks_v030_draft_practitioner_validation_test
      title 'Practitioner resources returned during previous tests conform to the Smart Health Checks Practitioner'
      description %(
This test verifies resources returned from the first search conform to
the [Smart Health Checks Practitioner](https://smartforms.csiro.au/ig/StructureDefinition/SHCPractitioner).
If at least one resource from the first search is invalid, the test will fail.

It verifies the presence of mandatory elements and that elements with
required bindings contain appropriate values. CodeableConcept element
bindings will fail if none of their codings have a code/system belonging
to the bound ValueSet. Quantity, Coding, and code element bindings will
fail if their code/system are not found in the valueset.

      )
      output :dar_code_found, :dar_extension_found

      def resource_type
        'Practitioner'
      end

      def scratch_resources
        scratch[:practitioner_resources] ||= {}
      end

      def filter_set
        []
      end

      run do
        perform_validation_test(scratch_resources[:all] || [],
                                'https://smartforms.csiro.au/ig/StructureDefinition/SHCPractitioner',
                                '0.3.0-draft',
                                skip_if_empty: true)
      end
    end
  end
end
