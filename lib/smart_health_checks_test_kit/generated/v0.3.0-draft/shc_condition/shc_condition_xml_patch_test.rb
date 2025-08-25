# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/patch_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class ShcConditionXMLPatchTest < Inferno::Test
      include InfernoSuiteGenerator::PatchTest

      title '(SHALL) Server returns correct Condition resource from Condition patch interaction (XMLPatch)'
      description 'A server SHALL support the Condition patch interaction (XMLPatch).'

      id :smart_health_checks_v030_draft_shc_condition_xml_patch_test

      def patch_data
        { resource_type: 'Condition', id: 'fever-pat-sf', patchset: [{ op: 'replace', path: '/Condition/clinicalStatus', value: { 'coding' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/condition-clinical', 'code' => 'inactive', 'display' => 'Inactive' }] } }] }
      end

      run do
        perform_xml_patch_test
      end
    end
  end
end
