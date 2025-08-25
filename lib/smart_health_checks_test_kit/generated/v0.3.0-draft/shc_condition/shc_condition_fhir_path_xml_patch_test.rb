# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/patch_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class ShcConditionFHIRPathXMLPatchTest < Inferno::Test
      include InfernoSuiteGenerator::PatchTest

      title '(SHALL) Server returns correct Condition resource from Condition patch interaction (FHIRPath Patch in XML format)'
      description 'A server SHALL support the Condition patch interaction (FHIRPath Patch in XML format).'

      id :smart_health_checks_v030_draft_shc_condition_fhirpath_xml_patch_test

      def patch_data
        { resource_type: 'Condition', id: 'fever-pat-sf', patchset: [{ 'parameter' => [{ 'name' => 'operation', 'part' => [{ 'name' => 'type', 'valueCode' => 'replace' }, { 'name' => 'path', 'valueString' => 'Condition.clinicalStatus' }, { 'name' => 'name', 'valueString' => 'clinicalStatus' }, { 'name' => 'value', 'valueCodeableConcept' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/condition-clinical', 'code' => 'inactive', 'display' => 'Inactive' }] } }, { 'name' => 'pathLabel', 'valueString' => 'Clinical status' }] }, { 'name' => 'operation', 'part' => [{ 'name' => 'type', 'valueCode' => 'replace' }, { 'name' => 'path', 'valueString' => 'Condition.abatement' }, { 'name' => 'name', 'valueString' => 'abatement' }, { 'name' => 'value', 'valueDateTime' => '2025-08-15' }, { 'name' => 'pathLabel', 'valueString' => 'Abatement date' }] }], 'resourceType' => 'Parameters' }] }
      end

      run do
        perform_fhirpath_patch_xml_text
      end
    end
  end
end
