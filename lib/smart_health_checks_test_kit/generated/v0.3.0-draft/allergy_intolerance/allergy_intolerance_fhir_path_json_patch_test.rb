# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/patch_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class AllergyIntoleranceFHIRPathJSONPatchTest < Inferno::Test
      include InfernoSuiteGenerator::PatchTest

      title '(SHALL) Server returns correct AllergyIntolerance resource from AllergyIntolerance patch interaction (FHIRPath Patch in JSON format)'
      description 'A server SHALL support the AllergyIntolerance patch interaction (FHIRPath Patch in JSON format).'

      id :smart_health_checks_v030_draft_allergy_intolerance_fhirpath_json_patch_test

      def patch_data
        { resource_type: 'AllergyIntolerance', id: '604a-pat-sf', patchset: { 'parameter' => [{ 'name' => 'operation', 'part' => [{ 'name' => 'type', 'valueCode' => 'replace' }, { 'name' => 'path', 'valueString' => 'AllergyIntolerance.clinicalStatus' }, { 'name' => 'name', 'valueString' => 'clinicalStatus' }, { 'name' => 'value', 'valueCodeableConcept' => { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical', 'code' => 'inactive', 'display' => 'Inactive' }] } }, { 'name' => 'pathLabel', 'valueString' => 'Clinical status' }] }, { 'name' => 'operation', 'part' => [{ 'name' => 'type', 'valueCode' => 'replace' }, { 'name' => 'path', 'valueString' => 'AllergyIntolerance.note[0].text' }, { 'name' => 'name', 'valueString' => 'text' }, { 'name' => 'value', 'valueMarkdown' => 'Duplicated allergy in record. Removed.' }, { 'name' => 'pathLabel', 'valueString' => 'Comment' }] }], 'resourceType' => 'Parameters' } }
      end

      run do
        perform_fhirpath_patch_json_test
      end
    end
  end
end
