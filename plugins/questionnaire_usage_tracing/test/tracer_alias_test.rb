# frozen_string_literal: true

require_relative 'support'
require 'minitest/mock'

module InfernoSuitePlugins
  module QuestionnaireUsageTracing
    # Verifies `Tracer` follows variable chains: items that read a query
    # through `text/fhirpath` variables count as its users.
    class TracerAliasTest < Minitest::Test
      include TracerFixtures

      # The GP CCMP chain: `ObsBodyHeight` -> `ObsBodyHeightLatest` ->
      # `ObsBodyHeightValue`, read by the `height` item.
      def test_an_item_reads_a_query_through_a_chain_of_aliases
        entry = trace(height_chain_form)[BODY_HEIGHT].first

        assert_equal [{ link_id: 'height', text: 'Height', extension: 'initialExpression', via: 'ObsBodyHeightValue',
                        reads: ['value.value'] }],
                     entry[:used_in]
        assert_equal ['status', 'value.value', 'value.unit'], entry[:elements_read]
      end

      def test_users_of_an_alias_that_stops_at_select_add_no_path
        form = questionnaire(
          extension: [query_variable('ObsBodyHeight', HEIGHT_QUERY),
                      fhirpath_variable('HeightCodes', '%ObsBodyHeight.entry.resource.code.select(coding.code)')],
          item: [item('codes', 'Codes', expression('initialExpression', '%HeightCodes.first().length()'))]
        )
        entry = trace(form)[BODY_HEIGHT].first

        assert_equal ['HeightCodes'], vias(entry)
        assert_equal ['code', 'code.coding.code'], entry[:elements_read]
      end

      def test_an_alias_on_an_item_is_not_visible_to_a_sibling
        entry = trace(alias_in_a_group_form)[BODY_HEIGHT].first

        assert_equal [{ link_id: 'vitals', text: 'Vitals', extension: 'variable' },
                      { link_id: 'height', text: 'Height', extension: 'initialExpression', via: 'HeightLatest',
                        reads: ['value'] }],
                     entry[:used_in]
        assert_equal ['value'], entry[:elements_read]
      end

      def test_each_expression_is_parsed_once
        parsed = Hash.new(0)
        parse = Fhirpath::Parser.method(:parse)
        counting_parse = lambda do |expression|
          parsed[expression] += 1
          parse.call(expression)
        end

        Fhirpath::Parser.stub(:parse, counting_parse) { trace(height_chain_form) }

        assert_equal [1], parsed.values.uniq
      end

      def test_each_chain_is_read_once_per_name
        read = Hash.new(0)
        paths_in = Ast.method(:paths_in)
        counting_paths_in = lambda do |tree, name, bundle:|
          read[[tree.object_id, name, bundle]] += 1
          paths_in.call(tree, name, bundle:)
        end

        Ast.stub(:paths_in, counting_paths_in) { trace(height_chain_form) }

        assert_equal [1], read.values.uniq
      end

      def test_aliases_that_reference_each_other_do_not_loop
        form = questionnaire(extension: [query_variable('ObsBodyHeight', HEIGHT_QUERY),
                                         fhirpath_variable('A', '%B | %ObsBodyHeight.entry.resource'),
                                         fhirpath_variable('B', '%A')],
                             item: [item('height', 'Height', expression('initialExpression', '%B.value'))])

        assert_equal ['B'], vias(trace(form)[BODY_HEIGHT].first)
      end

      private

      def height_chain_form
        latest = fhirpath_variable('ObsBodyHeightLatest',
                                   "%ObsBodyHeight.entry.resource.where(status = 'final').first()")
        value = fhirpath_variable('ObsBodyHeightValue', "%ObsBodyHeightLatest.value.where(unit = 'cm').value")
        questionnaire(
          extension: [query_variable('ObsBodyHeight', HEIGHT_QUERY), latest, value],
          item: [item('height', 'Height', expression('initialExpression', '%ObsBodyHeightValue.round(0)'))]
        )
      end

      # `HeightLatest` is defined on the `vitals` group. Its child `height` reads
      # it; the sibling `other` reads the same name, but can't see it.
      def alias_in_a_group_form
        height = item('height', 'Height', expression('initialExpression', '%HeightLatest.value'))
        other = item('other', 'Other', expression('initialExpression', '%HeightLatest.status'))
        vitals = item('vitals', 'Vitals', fhirpath_variable('HeightLatest', '%ObsBodyHeight.entry.resource.first()'),
                      children: [height])
        questionnaire(extension: [query_variable('ObsBodyHeight', HEIGHT_QUERY)], item: [vitals, other])
      end
    end
  end
end
