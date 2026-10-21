# frozen_string_literal: true

require_relative 'test_helper'

module InfernoSuitePlugins
  module QuestionnaireUsageTracing
    # Profiles and helpers shared by the `ProfileMatcher` tests. Body Height
    # fixes its code with a `patternCodeableConcept`, Body Weight with
    # `fixedCode` and `fixedUri` on a coding slice, like the real AU Core profiles.
    module ProfileMatcherFixtures
      LOINC = 'http://loinc.org'
      OBSERVATION_CATEGORY = 'http://terminology.hl7.org/CodeSystem/observation-category'
      BODY_HEIGHT = 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-bodyheight'
      BODY_WEIGHT = 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-bodyweight'
      PATHOLOGY_RESULT = 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-diagnosticresult-path'
      DIAGNOSTIC_RESULT = 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-diagnosticresult'
      AU_CORE_PATIENT = 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-patient'
      AU_BASE_PATIENT = 'http://hl7.org.au/fhir/StructureDefinition/au-patient'
      SNOMED = 'http://snomed.info/sct'
      RECORDED_SEX_URL = 'http://hl7.org/fhir/StructureDefinition/individual-recordedSexOrGender'

      def observation_profiles
        {
          BODY_HEIGHT => body_height,
          BODY_WEIGHT => body_weight,
          PATHOLOGY_RESULT => profile('Observation', pattern_element('Observation.category', 'laboratory')),
          DIAGNOSTIC_RESULT => profile('Observation')
        }
      end

      # The code as a `patternCodeableConcept`.
      def body_height
        profile('Observation', *vital_signs_category,
                pattern_element('Observation.code', '8302-2', system: LOINC))
      end

      # The code as `fixedCode` and `fixedUri` on a coding slice.
      def body_weight
        profile('Observation', *vital_signs_category,
                *coding_slice('Observation.code.coding:BodyWeightCode', LOINC, '29463-7'))
      end

      def vital_signs_category
        coding_slice('Observation.category:VSCat.coding', OBSERVATION_CATEGORY, 'vital-signs')
      end

      def coding_slice(id, system, code)
        path = id.gsub(/:[^.]+/, '')
        [{ 'id' => "#{id}.system", 'path' => "#{path}.system", 'fixedUri' => system },
         { 'id' => "#{id}.code", 'path' => "#{path}.code", 'fixedCode' => code }]
      end

      def pattern_element(path, code, system: OBSERVATION_CATEGORY)
        { 'id' => path, 'path' => path,
          'patternCodeableConcept' => { 'coding' => [{ 'system' => system, 'code' => code }] } }
      end

      def profile(type, *elements)
        { 'type' => type, 'elements' => [{ 'id' => type, 'path' => type }, *elements] }
      end

      def matcher_for(profiles)
        ProfileMatcher.new(*suite_for(profiles))
      end

      # The groups and `IGResources` of a suite with these profiles.
      def suite_for(profiles)
        ig_resources = InfernoSuiteGenerator::Generator::IGResources.new
        groups = profiles.map do |url, definition|
          ig_resources.add(structure_definition(url, definition))
          InfernoSuiteGenerator::Generator::GroupMetadata.new(resource: definition['type'], profile_url: url)
        end
        [groups, ig_resources]
      end

      def structure_definition(url, definition)
        FHIR::StructureDefinition.new(
          'resourceType' => 'StructureDefinition', 'url' => url, 'type' => definition['type'],
          'kind' => 'resource', 'derivation' => 'constraint',
          'snapshot' => { 'element' => definition['elements'] }
        )
      end

      def match_urls(matcher, query)
        input = ProfileMatcher.from_query(query)
        result = matcher.match(input[:resource_type], codes: input[:codes])
        result && { groups: result[:groups].map(&:profile_url), matched_by: result[:matched_by] }
      end
    end

    # Questionnaire builders shared by the `Tracer` tests. The suite has the
    # `ProfileMatcherFixtures` Observation profiles.
    module TracerFixtures
      include ProfileMatcherFixtures

      FORM_URL = 'http://www.health.gov.au/assessments/GPChronicConditionManagementPlan'
      FORM_TITLE = 'GP Chronic Condition Management Plan'
      HEIGHT_QUERY = 'Observation?code=8302-2&_sort=-date&patient={{%patient.id}}'
      WEIGHT_QUERY = 'Observation?code=29463-7&_sort=-date&patient={{%patient.id}}'

      def trace(form, profiles: observation_profiles, resources: [])
        groups, ig_resources = suite_for(profiles)
        [FHIR::Questionnaire.new(form), *resources].each { |resource| ig_resources.add(resource) }
        Tracer.new(ig_resources, groups).trace
      end

      def questionnaire(extension: [], item: [], contained: [])
        { 'resourceType' => 'Questionnaire', 'url' => FORM_URL, 'version' => '0.1.0',
          'title' => FORM_TITLE, 'status' => 'draft',
          'contained' => contained, 'extension' => extension, 'item' => item }
      end

      def item(link_id, text, *extensions, children: [])
        { 'linkId' => link_id, 'text' => text, 'type' => children.empty? ? 'decimal' : 'group',
          'extension' => extensions, 'item' => children }
      end

      # The questionnaire fields every trace entry starts with.
      def form_header
        { questionnaire_url: FORM_URL, questionnaire_version: '0.1.0', questionnaire_title: FORM_TITLE }
      end

      def link_ids(entry)
        entry[:used_in].map { |usage| usage[:link_id] }
      end

      def vias(entry)
        entry[:used_in].map { |usage| usage[:via] }
      end

      def query_variable(name, query)
        { 'url' => 'http://hl7.org/fhir/StructureDefinition/variable',
          'valueExpression' => { 'name' => name, 'language' => 'application/x-fhir-query', 'expression' => query } }
      end

      def expression(name, fhirpath)
        { 'url' => "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-#{name}",
          'valueExpression' => { 'language' => 'text/fhirpath', 'expression' => fhirpath } }
      end

      # `value_id: true` gives the name as `valueId`, like older SDC versions.
      def launch_context(name, *types, value_id: false)
        name_part = value_id ? { 'valueId' => name } : { 'valueCoding' => { 'code' => name } }
        { 'url' => 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-launchContext',
          'extension' => [{ 'url' => 'name', **name_part },
                          *types.map { |type| { 'url' => 'type', 'valueCode' => type } }] }
      end

      def assemble_context(name)
        { 'url' => 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-assembleContext',
          'valueString' => name }
      end

      def fhirpath_variable(name, fhirpath)
        { 'url' => 'http://hl7.org/fhir/StructureDefinition/variable',
          'valueExpression' => { 'name' => name, 'language' => 'text/fhirpath', 'expression' => fhirpath } }
      end
    end
  end
end
