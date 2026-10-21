# frozen_string_literal: true

require_relative 'support'

module InfernoSuitePlugins
  module QuestionnaireUsageTracing
    # Builds and checks the chains `Ast.paths` returns.
    module AstPathAssertions
      private

      def chain(path, type: nil, stopped: false, types: [type].compact, criteria: [])
        { type:, types:, path:, stopped:, criteria: }
      end

      def assert_paths(expected, expression, name, bundle: false)
        assert_equal expected, Ast.paths(expression, name, bundle:)
      end
    end

    # Verifies `Ast` reads `%Name` references and element paths from the
    # FHIRPath AST, using expressions from the 715 Health Check and GP CCMP forms.
    class AstTest < Minitest::Test
      include ProfileMatcherFixtures
      include AstPathAssertions

      def test_references_returns_the_external_constant_names
        assert_equal ['ObsBodyHeight'], Ast.references('%ObsBodyHeight.entry')
      end

      def test_references_lists_each_name_once
        assert_equal %w[A B], Ast.references('%A.x | %B.where(y = %A.z)')
      end

      def test_references_strips_backticks
        assert_equal ['vs-x'], Ast.references('%`vs-x`.code')
      end

      def test_references_ignores_a_name_inside_a_string_literal
        assert_empty Ast.references("'%Foo'")
      end

      def test_references_returns_empty_and_logs_on_bad_syntax
        assert_output(/skipping FHIRPath/) { assert_empty Ast.references('%%bad((') }
      end

      def test_paths_returns_empty_and_logs_on_bad_syntax
        assert_output(/skipping FHIRPath/) { assert_empty Ast.paths('%%bad((', 'bad', bundle: false) }
      end

      def test_paths_ignores_chains_from_other_names
        assert_empty Ast.paths('%patient.birthDate', 'user', bundle: false)
      end

      def test_paths_drops_function_calls
        assert_paths [chain('birthDate')], '%patient.birthDate.toString()', 'patient'
      end

      def test_paths_reads_a_where_filter_on_a_member_as_a_criteria
        assert_paths [chain('telecom.value', criteria: ['telecom.system'])],
                     "%patient.telecom.where(system='phone').value", 'patient'
      end

      def test_paths_keeps_the_url_of_an_extension_filter
        assert_paths [chain("extension[url=#{RECORDED_SEX_URL}]")],
                     "%patient.extension.where(url='#{RECORDED_SEX_URL}').exists()", 'patient'
      end

      def test_paths_keeps_the_url_of_the_extension_function
        assert_paths [chain("extension[url=#{RECORDED_SEX_URL}]")],
                     "%patient.extension('#{RECORDED_SEX_URL}').exists()", 'patient'
      end

      def test_paths_keeps_the_url_of_an_extension_filter_inside_exists_and_and
        expression = "%patient.extension.where(exists(url='#{RECORDED_SEX_URL}' and " \
                     "extension.where(url='type').exists()) and (url != 'x')).extension.where(url='value').value"

        path = "extension[url=#{RECORDED_SEX_URL}].extension[url=value].value"

        assert_paths [chain(path)], expression, 'patient'
      end

      def test_paths_does_not_take_the_url_of_a_not_equal_filter
        assert_paths [chain('extension.value', criteria: ['extension.url'])],
                     "%p.extension.where(url != 'http://x/a').value", 'p'
      end

      def test_paths_does_not_take_the_url_of_a_sub_extension_filter
        assert_paths [chain('extension.value', criteria: ['extension.extension[url=type]'])],
                     "%patient.extension.where(extension.where(url='type').exists()).value", 'patient'
      end

      def test_paths_gives_an_empty_path_for_a_chain_that_only_picks_the_resource
        assert_paths [chain('', criteria: ['status'])],
                     "%ObsBodyHeight.entry.resource.where(status = 'final' or status = 'amended').first()",
                     'ObsBodyHeight', bundle: true
      end

      def test_paths_stops_at_select_after_reading_its_argument
        assert_paths [chain('name', stopped: true, criteria: ['name.given', 'name.family'])],
                     "%user.name.select(given.first() + ' ' + family)", 'user'
      end

      def test_paths_stops_at_of_type_outside_a_bundle
        assert_paths [chain('value', stopped: true)], '%obs.value.ofType(Quantity).value', 'obs'
      end

      def test_paths_stops_where_the_chain_leaves_the_resource
        assert_paths [chain('subject', stopped: true)], '%obs.subject.resolve().name.given', 'obs'
        assert_paths [chain('component', stopped: true)], '%obs.component.descendants().value', 'obs'
        assert_paths [chain('', stopped: true)], '%obs.children().code', 'obs'
      end

      def test_paths_reads_an_alias_chain
        assert_paths [chain('value.value', criteria: ['value.unit'])],
                     "%ObsBodyHeightLatest.value.where(unit = 'cm').value", 'ObsBodyHeightLatest'
      end
    end

    # Verifies `Ast.paths` reads the type and path of a chain through a query's
    # Bundle, and tells a read of the Bundle itself apart.
    class AstBundlePathTest < Minitest::Test
      include AstPathAssertions

      def test_paths_reads_the_type_of_a_bundle_chain_from_of_type
        assert_paths [chain('', type: 'Location')],
                     '%PractitionerRoleLocation.entry.resource.ofType(Location)',
                     'PractitionerRoleLocation', bundle: true
      end

      def test_paths_reads_the_query_own_type_from_of_type
        assert_paths [chain('', type: 'MedicationStatement')],
                     '%MedicationStatement.entry.resource.ofType(MedicationStatement)',
                     'MedicationStatement', bundle: true
      end

      def test_paths_skips_functions_between_entry_and_resource
        assert_paths [chain('code')], '%q.entry.first().resource.code', 'q', bundle: true
      end

      def test_paths_reads_the_type_of_a_bundle_chain_from_an_is_filter_on_entry
        assert_paths [chain('code', type: 'Observation')],
                     '%q.entry.where(resource is Observation).resource.code', 'q', bundle: true
        assert_paths [chain('', type: 'Observation')],
                     '%q.entry.where(resource.is(FHIR.Observation)).resource', 'q', bundle: true
      end

      def test_paths_takes_no_type_from_an_as_filter_on_entry
        assert_paths [chain('code')], '%q.entry.where(resource as Observation).resource.code', 'q', bundle: true
      end

      def test_paths_reads_the_type_of_a_chain_that_ends_at_entries
        assert_paths [chain('', type: 'Condition').merge(entries: true)],
                     '%q.entry.where(resource is Condition)', 'q', bundle: true
        assert_paths [chain('', type: 'Condition').merge(entries: true)],
                     '%q.entry.where(resource is Condition).first()', 'q', bundle: true
      end

      def test_paths_reads_an_alias_of_entries_from_its_resource
        assert_paths [chain('code')], '%conds.resource.code', 'conds', bundle: :entries
        assert_paths [chain('', type: 'Condition').merge(entries: true)],
                     '%conds.where(resource is Condition)', 'conds', bundle: :entries
      end

      def test_paths_gives_no_element_for_a_chain_that_reads_the_bundle
        bundle_read = chain('', stopped: true)

        assert_paths [bundle_read], '%q.total > 0', 'q', bundle: true
        assert_paths [bundle_read], '%q.entry.count()', 'q', bundle: true
        assert_paths [bundle_read], '%q.entry.fullUrl', 'q', bundle: true
      end

      def test_paths_finds_chains_nested_in_function_arguments
        expression = '%MedicationStatement.entry.resource.ofType(Medication)' \
                     '.where(id in %MedicationStatement.entry.resource.medication.select(reference))'

        assert_paths [chain('', type: 'Medication', criteria: ['id']),
                      chain('medication', stopped: true, criteria: ['medication.reference'])],
                     expression, 'MedicationStatement', bundle: true
      end
    end

    # Verifies `Ast.paths` reads the elements in the criteria of `where`,
    # `exists`, `all` and `select`, and the resource types a
    # `where(resourceType = 'T')` names, using expressions from the 715
    # Absolute CVD Risk module.
    class AstCriteriaPathTest < Minitest::Test
      include AstPathAssertions

      def test_paths_reads_nested_criteria_relative_to_their_chain
        expression = "%conditions.entry.resource.where(clinicalStatus.coding.exists(code = 'active'))" \
                     ".where(verificationStatus.coding.all(code.empty() or code = 'confirmed'))"

        assert_paths [chain('', criteria: ['clinicalStatus.coding', 'clinicalStatus.coding.code',
                                           'verificationStatus.coding', 'verificationStatus.coding.code'])],
                     expression, 'conditions', bundle: true
      end

      def test_paths_reads_this_and_the_arguments_of_an_unqualified_function
        assert_paths [chain('', criteria: %w[id intent authoredOn])],
                     "%meds.where($this.id.exists() and iif(intent = 'order', authoredOn > now(), false))", 'meds'
      end

      def test_paths_leaves_a_chain_from_another_name_in_a_criteria_to_that_name
        expression = "%meds.where(id in %orders.medicationReference.select(reference.replace('Medication/', '')))"

        assert_paths [chain('', criteria: ['id'])], expression, 'meds'
      end

      def test_paths_reads_the_type_of_a_where_resource_type_on_the_resource
        assert_paths [chain('', type: 'Medication', criteria: %w[id code])],
                     "%meds.where(resourceType = 'Medication' and id = 'x').where(code.exists())", 'meds'
      end

      def test_paths_names_each_type_of_a_where_resource_type_in_an_or
        expression = "%MedicationRequest.entry.resource.where(intent = 'order' or resourceType = 'Medication')"

        assert_paths [chain('', types: ['Medication'], criteria: ['intent'])],
                     expression, 'MedicationRequest', bundle: true
      end

      def test_paths_takes_no_type_from_a_where_resource_type_on_an_element
        assert_paths [chain('contained', criteria: ['contained.code'])],
                     "%meds.contained.where(resourceType = 'Medication').where(code.exists())", 'meds'
      end
    end
  end
end
