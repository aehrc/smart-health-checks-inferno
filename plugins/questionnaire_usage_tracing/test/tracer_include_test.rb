# frozen_string_literal: true

require_relative 'support'

module InfernoSuitePlugins
  module QuestionnaireUsageTracing
    # Verifies `Tracer` traces `_include` targets as their own entries, and
    # routes each chain to the include or the query entry by its type.
    class TracerIncludeTest < Minitest::Test
      include TracerFixtures

      MEDICATION_STATEMENT = 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-medicationstatement'
      MEDICATION = 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-medication'
      PRACTITIONER_ROLE = 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-practitionerrole'
      LOCATION = 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-location'
      MEDS_QUERY = 'MedicationStatement?patient={{%patient.id}}&status=active&_include=MedicationStatement:medication'
      LOCATION_NAME_EXPRESSION = '%PractitionerRoleLocation.entry.resource.ofType(Location).first().name'
      MEDS_EXPRESSION = '%MedicationStatement.entry.resource.ofType(Medication)' \
                        '.where(id in %MedicationStatement.entry.resource.medication.select(reference))'

      def test_an_include_entry_on_the_target_group_from_the_search_parameter
        traces = trace(medications_form, profiles: suite_profiles, resources: [medication_param])

        assert_equal [medication_entry], traces[MEDICATION]
      end

      def test_a_chain_without_of_type_in_the_same_item_goes_to_the_query_entry
        traces = trace(medications_form, profiles: suite_profiles, resources: [medication_param])
        entry = traces[MEDICATION_STATEMENT].first

        assert_equal 'query', entry[:source]
        assert_equal ['medications'], link_ids(entry)
        assert_equal ['medication', 'medication.reference'], entry[:elements_read]
      end

      def test_an_explicit_target_type
        entry = trace(location_form('PractitionerRole:location:Location'), profiles: suite_profiles)[LOCATION].first

        assert_equal 'explicit', entry[:target_by]
        assert_equal ['name'], entry[:elements_read]
        assert_equal ['location'], link_ids(entry)
      end

      def test_a_target_type_from_of_type_in_the_form
        entry = trace(location_form('PractitionerRole:location'), profiles: suite_profiles)[LOCATION].first

        assert_equal 'of_type', entry[:target_by]
        assert_equal 'PractitionerRole:location', entry[:include]
      end

      def test_an_include_without_a_search_parameter_or_of_type_is_unresolved
        query = location_query('PractitionerRole:location')
        form = questionnaire(extension: [query_variable('PractitionerRoleLocation', query)])

        assert_output(/unresolved .* include PractitionerRole:location: no target type/) do
          refute trace(form, profiles: suite_profiles).key?(LOCATION)
        end
      end

      def test_an_include_of_the_query_own_type_leaves_its_chains_with_the_query_entry
        query_entry, include_entry = trace(own_type_include_form)[BODY_HEIGHT].partition do |entry|
          entry[:source] == 'query'
        end.map(&:first)

        assert_equal [['height'], ['value']], [link_ids(query_entry), query_entry[:elements_read]]
        assert_empty include_entry[:used_in]
      end

      def test_an_include_iterate_is_skipped
        query = "#{MEDS_QUERY}&_include:iterate=Medication:manufacturer"
        form = questionnaire(extension: [query_variable('MedicationStatement', query)])

        assert_output(/skipping _include:iterate=Medication:manufacturer/) do
          trace(form, profiles: suite_profiles, resources: [medication_param])
        end
      end

      private

      def suite_profiles
        { MEDICATION_STATEMENT => profile('MedicationStatement'), MEDICATION => profile('Medication'),
          PRACTITIONER_ROLE => profile('PractitionerRole'), LOCATION => profile('Location') }
      end

      def medication_param
        FHIR::SearchParameter.new('resourceType' => 'SearchParameter', 'url' => 'http://example.org/medication',
                                  'name' => 'medication', 'status' => 'active', 'code' => 'medication',
                                  'base' => ['MedicationStatement'], 'type' => 'reference', 'target' => ['Medication'])
      end

      def medications_form
        questionnaire(extension: [query_variable('MedicationStatement', MEDS_QUERY)],
                      item: [item('medications', 'Medications', expression('initialExpression', MEDS_EXPRESSION))])
      end

      def medication_entry
        {
          source: 'include', **form_header, name: 'MedicationStatement', defined_at: 'root', query: MEDS_QUERY,
          include: 'MedicationStatement:medication', target_by: 'search_parameter', matched_by: 'resource_type',
          elements_read: ['id'],
          used_in: [{ link_id: 'medications', text: 'Medications', extension: 'initialExpression', reads: ['id'] }]
        }
      end

      # A Body Height query that also includes the Observations its results
      # have as members.
      def own_type_include_form
        questionnaire(
          extension: [query_variable('Heights', 'Observation?code=8302-2&_include=Observation:has-member:Observation')],
          item: [item('height', 'Height',
                      expression('initialExpression', '%Heights.entry.resource.ofType(Observation).value'))]
        )
      end

      def location_query(include)
        "PractitionerRole?practitioner={{%user.id}}&_include=#{include}"
      end

      def location_form(include)
        questionnaire(
          extension: [query_variable('PractitionerRoleLocation', location_query(include))],
          item: [item('location', 'Location', expression('initialExpression', LOCATION_NAME_EXPRESSION))]
        )
      end
    end
  end
end
