# frozen_string_literal: true

require_relative 'support'

module InfernoSuitePlugins
  module QuestionnaireUsageTracing
    # Verifies `Tracer` routes a chain that picks entries with
    # `entry.where(resource is T)` to the include entry of `T`, directly or
    # through an alias of the picked entries.
    class TracerEntryFilterTest < Minitest::Test
      include TracerFixtures

      PRACTITIONER_ROLE = 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-practitionerrole'
      LOCATION = 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-location'
      QUERY = 'PractitionerRole?practitioner={{%user.id}}&_include=PractitionerRole:location:Location'

      def test_an_is_filter_on_entry_routes_a_chain_to_its_include_entry
        traces = location_traces('%PractitionerRoleLocation.entry.where(resource is Location).resource.name')

        assert_equal ['name'], traces[LOCATION].first[:elements_read]
        assert_empty traces[PRACTITIONER_ROLE].first[:used_in]
      end

      def test_an_alias_of_filtered_entries_routes_its_chains_to_the_include_entry
        locations = fhirpath_variable('Locations', '%PractitionerRoleLocation.entry.where(resource is Location)')
        traces = location_traces('%Locations.resource.name', variables: [locations])

        assert_equal [['name'], ['Locations']], [traces[LOCATION].first[:elements_read], vias(traces[LOCATION].first)]
        assert_empty traces[PRACTITIONER_ROLE].first[:used_in]
      end

      private

      # The traces of a form whose `location` item reads `fhirpath`.
      def location_traces(fhirpath, variables: [])
        form = questionnaire(extension: [query_variable('PractitionerRoleLocation', QUERY), *variables],
                             item: [item('location', 'Location', expression('initialExpression', fhirpath))])
        trace(form, profiles: { PRACTITIONER_ROLE => profile('PractitionerRole'), LOCATION => profile('Location') })
      end
    end
  end
end
