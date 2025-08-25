# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/patch_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class AllergyIntoleranceJSONPatchTest < Inferno::Test
      include InfernoSuiteGenerator::PatchTest

      title '(SHALL) Server returns correct AllergyIntolerance resource from AllergyIntolerance patch interaction (JSONPatch)'
      description 'A server SHALL support the AllergyIntolerance patch interaction (JSONPatch).'

      id :smart_health_checks_v030_draft_allergy_intolerance_json_patch_test

      def patch_data
        { resource_type: 'AllergyIntolerance', id: '604a-pat-sf', patchset: { op: 'replace', path: '/AllergyIntolerance/clinicalStatus', value: { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical', 'code' => 'inactive', 'display' => 'Inactive' }] } } }
      end

      run do
        perform_json_patch_test
      end
    end
  end
end
