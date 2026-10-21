# frozen_string_literal: true

require_relative 'support'

module InfernoSuitePlugins
  module QuestionnaireUsageTracing
    # Entries and a Patient group shared by the `UsageSection` tests.
    module UsageSectionFixtures
      include TracerFixtures

      INDIGENOUS_STATUS = 'http://hl7.org.au/fhir/StructureDefinition/indigenous-status'
      PRONOUNS = 'http://hl7.org/fhir/StructureDefinition/individual-pronouns'
      LOCATION_QUERY = 'PractitionerRole?_id={{%role.id}}&_include=PractitionerRole:location'

      # The Markdown without its heading and intro.
      def section(entries, group: patient_group)
        UsageSection.new(entries, group).markdown.lines.drop(4).join
      end

      def launch_entry(reads: ['birthDate'],
                       used_in: [{ link_id: 'dob', text: 'Date of birth', extension: 'initialExpression', reads: }])
        { source: 'launch_context', **form_header, name: 'patient', used_in: }
      end

      def variable_usage
        { link_id: 'group', text: 'Group', extension: 'variable', reads: ['name'] }
      end

      def query_entry(query, used_in: [{ link_id: 'name', text: 'Name', extension: 'initialExpression' }])
        { source: 'query', **form_header, name: 'Patients', query:, used_in: }
      end

      def template_entry(patch:, template_codes: [],
                         used_in: [{ link_id: 'height', text: 'Height', extension: 'templateExtract' }])
        { source: 'template_extract', **form_header, name: 'height', patch:, template_codes:, used_in: }
      end

      def patient_group(searches: [{ names: ['_id'] }, { names: %w[family gender] }])
        InfernoSuiteGenerator::Generator::GroupMetadata.new(
          resource: 'Patient', profile_url: AU_CORE_PATIENT, searches:, mandatory_elements: ['Patient.gender'],
          must_supports: { elements: [{ path: 'birthDate' }, { path: 'deceasedBoolean' }],
                           slices: [{ slice_id: 'Patient.deceased[x]:deceasedBoolean', path: 'deceased[x]' }],
                           extensions: [{ id: 'Patient.extension:indigenousStatus', url: INDIGENOUS_STATUS }] }
        )
      end
    end

    # Verifies the `UsageSection` Markdown for each kind of source, the search
    # check, and which sources it leaves out.
    class UsageSectionTest < Minitest::Test
      include UsageSectionFixtures

      def test_a_launch_context_lists_its_items_under_the_questionnaire
        assert_equal <<~MARKDOWN, section([launch_entry])
          - **#{FORM_TITLE}**
            - **Launch context patient**: the Patient the form is opened for
              - **Date of birth**: pre-fills the answer; reads birthDate
        MARKDOWN
      end

      def test_a_query_shows_its_request_and_that_the_group_tests_its_search
        markdown = section([query_entry('Patient?gender:not=male&_sort=-birthdate&family={{%name}}')])

        assert_includes markdown, <<~MARKDOWN
          - **Query Patients**: searches Patient resources
              - Request: Patient?gender:not=male&_sort=-birthdate&family={{%name}}
              - This group tests the same search: family + gender
              - **Name**: pre-fills the answer
        MARKDOWN
      end

      def test_a_query_whose_search_the_group_does_not_test
        assert_includes section([query_entry('Patient?name={{%name}}&_count=1')]),
                        "- **Not tested by this group:** a search by name; it tests _id, family + gender\n"
      end

      def test_a_group_without_searches_says_only_that_the_search_is_not_tested
        markdown = section([query_entry('Patient?_id=1')], group: patient_group(searches: []))

        assert_includes markdown, "- **Not tested by this group:** a search by _id\n"
      end

      def test_a_query_no_item_reads_is_shown_only_when_it_includes_other_resources
        assert_includes section([query_entry(LOCATION_QUERY, used_in: [])]),
                        "- No item reads its results; it fetches PractitionerRole:location through _include\n"
        assert_empty section([query_entry('Patient?_id=1', used_in: [])])
      end

      def test_sources_no_item_uses_are_left_out
        section = UsageSection.new([launch_entry(used_in: []), launch_entry(used_in: [variable_usage])], patient_group)

        assert_predicate section, :empty?
      end

      def test_an_include_entry
        entry = { source: 'include', questionnaire_title: FORM_TITLE, name: 'Roles', query: LOCATION_QUERY,
                  include: 'PractitionerRole:location', used_in: [{ link_id: 'loc', text: 'Location' }] }

        assert_includes section([entry]), <<~MARKDOWN
          - **Query Roles**: fetches Patient resources through _include=PractitionerRole:location
              - Request: #{LOCATION_QUERY}
              - **Location**
        MARKDOWN
      end

      def test_extraction_templates
        create = template_entry(patch: false, template_codes: ['http://loinc.org|8302-2'])
        markdown = section([create, template_entry(patch: true, used_in: [])])

        assert_includes markdown, '- **Extraction template height**: creates a new Patient with code ' \
                                  "http://loinc.org|8302-2 from the answers\n    " \
                                  "- **Height**: its answers fill the template\n"
        assert_includes markdown, '- **Extraction template height**: updates an existing Patient with a ' \
                                  "FHIRPath Patch\n    - Its answers come from the whole form\n"
      end

      def test_questionnaires_with_the_same_title_show_their_version
        assembled = launch_entry.merge(questionnaire_version: '0.1.0-assembled')
        markdown = section([launch_entry, assembled])

        assert_includes markdown, "- **#{FORM_TITLE}, version 0.1.0**\n"
        assert_includes markdown, "- **#{FORM_TITLE}, version 0.1.0-assembled**\n"
      end

      def test_untitled_questionnaires_with_the_same_url_show_their_version
        untitled = launch_entry.except(:questionnaire_title)
        markdown = section([untitled, untitled.merge(questionnaire_version: '0.2.0')])

        assert_includes markdown, "- **#{FORM_URL}, version 0.1.0**\n"
        assert_includes markdown, "- **#{FORM_URL}, version 0.2.0**\n"
      end

      def test_a_query_whose_only_include_is_not_traced_is_left_out
        query = 'PractitionerRole?_id=1&_include:iterate=PractitionerRole:location'

        assert_empty section([query_entry(query, used_in: [])])
      end

      def test_a_compartment_search_selects_by_its_compartment
        group = patient_group(searches: [{ names: %w[patient code] }])

        assert_includes section([query_entry('Patient/{{%patient.id}}/Observation?code=x')], group:),
                        "- This group tests the same search: patient + code\n"
      end

      def test_questionnaires_without_a_url_stay_apart
        first = launch_entry.except(:questionnaire_url).merge(questionnaire_id: 'first')
        second = launch_entry.except(:questionnaire_url, :questionnaire_title).merge(questionnaire_id: 'second')
        markdown = section([first, second])

        assert_includes markdown, "- **#{FORM_TITLE}**\n"
        assert_includes markdown, "- **second**\n"
      end

      def test_a_read_says_it_reads_one_resource
        entry = query_entry('Patient/{{%patient.id}}').merge(read: true)

        assert_includes section([entry]), "- **Query Patients**: reads one Patient by id\n"
      end
    end

    # Verifies the `UsageSection` item lines: labels, read paths and the Must
    # Support check.
    class UsageSectionItemTest < Minitest::Test
      include UsageSectionFixtures

      def test_a_must_support_extension_is_named_by_its_slice
        markdown = section([launch_entry(reads: ["extension[url=#{INDIGENOUS_STATUS}].value"])])

        assert_includes markdown, "**Date of birth**: pre-fills the answer; reads extension:indigenousStatus.value\n"
      end

      def test_an_extension_that_is_not_must_support_is_shortened_and_marked
        markdown = section([launch_entry(reads: ["extension[url=#{PRONOUNS}].extension[url=value].value"])])

        assert_includes markdown, "reads extension[individual-pronouns].extension[value].value (not checked)\n"
      end

      def test_mandatory_elements_and_id_count_as_checked
        assert_includes section([launch_entry(reads: %w[gender id contact])]),
                        "reads gender, id, contact (not checked)\n"
      end

      # The profile marks `deceasedBoolean` with a type slice on
      # `deceased[x]`; FHIRPath reads it as `deceased`.
      def test_a_choice_element_with_a_must_support_type_slice_counts_as_checked
        assert_includes section([launch_entry(reads: %w[deceased])]), "reads deceased\n"
      end

      def test_a_choice_element_read_by_its_type_counts_as_checked
        assert_includes section([launch_entry(reads: %w[deceasedBoolean deceasedDateTime.value])]),
                        "reads deceasedBoolean, deceasedDateTime.value (not checked)\n"
      end

      def test_a_usage_on_the_root_is_named_as_the_whole_form
        markdown = section([launch_entry(used_in: [{ extension: 'itemExtractionContext', reads: ['name'] }])])

        assert_includes markdown, "- **The whole form**: sets the extraction context; reads name (not checked)\n"
      end

      def test_an_item_without_text_is_named_by_its_link_id
        markdown = section([launch_entry(used_in: [{ link_id: 'dob', extension: 'maxValue' }])])

        assert_includes markdown, "- **dob**: maxValue\n"
      end

      def test_markdown_in_an_item_text_is_escaped
        markdown = section([launch_entry(used_in: [{ link_id: 'dob', text: 'Date *of* birth_x' }])])

        assert_includes markdown, "- **Date \\*of\\* birth\\_x**\n"
      end

      def test_items_beyond_the_limit_are_counted
        used_in = (1..27).map { |index| { link_id: "item-#{index}", text: "Item #{index}" } }
        markdown = section([launch_entry(used_in:)])

        assert_includes markdown, '**Item 25**'
        refute_includes markdown, '**Item 26**'
        assert_includes markdown, "- and 2 more items, listed in plugins.yml\n"
      end
    end
  end
end
