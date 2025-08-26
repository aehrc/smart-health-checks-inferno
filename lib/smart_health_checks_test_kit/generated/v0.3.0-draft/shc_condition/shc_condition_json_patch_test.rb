# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/patch_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class ShcConditionJSONPatchTest < Inferno::Test
      include InfernoSuiteGenerator::PatchTest

      title '(SHALL) Server returns correct Condition resource from Condition patch interaction (JSONPatch)'
      description 'A server SHALL support the Condition patch interaction (JSONPatch).'

      id :smart_health_checks_v030_draft_shc_condition_json_patch_test

      def resource_type
        'Condition'
      end

      run do
        perform_json_patch_test
      end
    end
  end
end
