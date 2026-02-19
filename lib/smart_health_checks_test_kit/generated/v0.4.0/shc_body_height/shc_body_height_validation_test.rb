# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/validation_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV040
    class ShcBodyHeightValidationTest < Inferno::Test
      include InfernoSuiteGenerator::ValidationTest

      id :smart_health_checks_v040_shc_body_height_validation_test
      title 'Observation resources returned during previous tests conform to the Smart Health Checks Body Height'
      description %(
This test verifies resources returned from the first search conform to
the [Smart Health Checks Body Height](https://smartforms.csiro.au/ig/StructureDefinition/SHCBodyHeight).
If at least one resource from the first search is invalid, the test will fail.

It verifies the presence of mandatory elements and that elements with
required bindings contain appropriate values. CodeableConcept element
bindings will fail if none of their codings have a code/system belonging
to the bound ValueSet. Quantity, Coding, and code element bindings will
fail if their code/system are not found in the valueset.

      )
      output :dar_code_found, :dar_extension_found

      def resource_type
        'Observation'
      end

      def scratch_resources
        scratch[:shc_body_height_resources] ||= {}
      end

      def filter_set
        [[{ 'expression' => "code.coding.where(system = 'http://loinc.org').code", 'value' => '8302-2' }], [{ 'expression' => "code.coding.where(system = 'http://snomed.info/sct').code", 'value' => '50373000' }]]
      end

      run do
        perform_validation_test(scratch_resources[:all] || [],
                                'https://smartforms.csiro.au/ig/StructureDefinition/SHCBodyHeight',
                                '0.4.0',
                                skip_if_empty: true)
      end
    end
  end
end
