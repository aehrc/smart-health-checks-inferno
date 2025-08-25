# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/patch_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class PatientXMLPatchTest < Inferno::Test
      include InfernoSuiteGenerator::PatchTest

      title '(SHALL) Server returns correct Patient resource from Patient patch interaction ()'
      description 'A server SHALL support the Patient patch interaction ().'

      id :smart_health_checks_v030_draft_patient__patch_test

      def patch_data; end

      run do
      end
    end
  end
end
