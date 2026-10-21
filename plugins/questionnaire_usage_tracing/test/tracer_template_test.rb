# frozen_string_literal: true

require_relative 'support'

module InfernoSuitePlugins
  module QuestionnaireUsageTracing
    # Verifies `Tracer` traces `templateExtract` templates to the profile of the
    # resource they create or patch.
    class TracerTemplateTest < Minitest::Test
      include TracerFixtures

      AU_CORE_CONDITION = 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-condition'
      PATCH_URL = 'https://smartforms.csiro.au/ig/StructureDefinition/TemplateExtractExtensionPatchRequestUrl'

      def test_an_item_with_a_body_height_template
        form = questionnaire(contained: [body_height_template],
                             item: [item('height', 'Height', template_extract('#BodyHeightTemplate'))])

        assert_equal [{
          source: 'template_extract', **form_header,
          name: 'BodyHeightTemplate', defined_at: 'height',
          template_codes: ["#{LOINC}|8302-2", "#{SNOMED}|50373000"], patch: false, matched_by: 'code',
          used_in: [{ link_id: 'height', text: 'Height', extension: 'templateExtract' }]
        }], trace(form, profiles: suite_profiles)[BODY_HEIGHT]
      end

      def test_a_patch_template_targets_the_type_in_its_operation_paths
        form = questionnaire(contained: [condition_patch_template(path: 'Condition')],
                             item: [item('condition', 'Condition', condition_patch_extract)])
        entry = trace(form, profiles: suite_profiles)[AU_CORE_CONDITION].first

        assert entry[:patch]
        assert_empty entry[:template_codes]
        assert_equal 'resource_type', entry[:matched_by]
      end

      def test_a_patch_template_without_paths_targets_the_type_in_its_request_url
        form = questionnaire(contained: [condition_patch_template],
                             item: [item('condition', 'Condition', condition_patch_extract)])

        assert_equal 'ConditionPatchTemplate', trace(form, profiles: suite_profiles)[AU_CORE_CONDITION].first[:name]
      end

      def test_a_template_on_the_root_has_no_items
        form = questionnaire(contained: [body_height_template], extension: [template_extract('#BodyHeightTemplate')])
        entry = trace(form, profiles: suite_profiles)[BODY_HEIGHT].first

        assert_equal 'root', entry[:defined_at]
        assert_empty entry[:used_in]
      end

      def test_a_reference_to_a_missing_contained_resource_is_skipped
        form = questionnaire(item: [item('height', 'Height', template_extract('#Missing'))])

        assert_output(/skipping .* templateExtract #Missing on height: no contained resource #Missing/) do
          assert_empty trace(form, profiles: suite_profiles)
        end
      end

      private

      def suite_profiles
        observation_profiles.merge(AU_CORE_CONDITION => profile('Condition'))
      end

      def template_extract(reference, patch_url: nil)
        parts = [{ 'url' => 'template', 'valueReference' => { 'reference' => reference } }]
        parts << { 'url' => PATCH_URL, 'valueString' => patch_url } if patch_url
        { 'url' => 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-templateExtract',
          'extension' => parts }
      end

      def condition_patch_extract
        template_extract('#ConditionPatchTemplate',
                         patch_url: "'Condition/' + item.where(linkId='conditionId').answer.value")
      end

      def body_height_template
        { 'resourceType' => 'Observation', 'id' => 'BodyHeightTemplate', 'status' => 'final',
          'category' => [{ 'coding' => [{ 'system' => OBSERVATION_CATEGORY, 'code' => 'vital-signs' }] }],
          'code' => { 'coding' => [{ 'system' => LOINC, 'code' => '8302-2' },
                                   { 'system' => SNOMED, 'code' => '50373000' }] } }
      end

      # A FHIRPath Patch `Parameters`, with one `add` operation on `path` when
      # given.
      def condition_patch_template(path: nil)
        parts = [{ 'name' => 'type', 'valueCode' => 'add' }, { 'name' => 'name', 'valueString' => 'clinicalStatus' }]
        parts << { 'name' => 'path', 'valueString' => path } if path
        { 'resourceType' => 'Parameters', 'id' => 'ConditionPatchTemplate',
          'parameter' => [{ 'name' => 'operation', 'part' => parts }] }
      end
    end
  end
end
