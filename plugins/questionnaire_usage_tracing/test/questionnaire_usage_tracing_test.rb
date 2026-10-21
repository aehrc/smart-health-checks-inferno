# frozen_string_literal: true

require 'tmpdir'
require_relative 'support'

module InfernoSuitePlugins
  module QuestionnaireUsageTracing
    # Runs the plugin through the host's Loader over a suite with one Patient group and reads what it wrote.
    class PluginTest < Minitest::Test
      include InfernoSuiteGenerator::Plugins::Testing
      include TracerFixtures

      PLUGIN_ROOT = File.expand_path('..', __dir__)

      def setup
        @dir = Dir.mktmpdir
        @group = build_group_metadata
      end

      def teardown
        FileUtils.remove_entry(@dir)
      end

      def test_a_traced_group_gets_its_entries_in_plugins_yml
        run_plugin_with(patient_form)

        entries = plugin_metadata(group_dir, 'questionnaire_usage_tracing')['entries']

        assert_equal(['launch_context'], entries.map { |entry| entry['source'] })
        assert_equal ['birthDate'], entries.first['elements_read']
      end

      def test_a_traced_group_gets_the_section_in_its_description
        descriptions = run_plugin_with(patient_form)

        assert_equal 1, descriptions.for(@group).size
        assert descriptions.for(@group).first.start_with?('## Used in questionnaires')
      end

      def test_a_group_without_a_trace_gets_no_plugins_yml_and_no_section
        descriptions = run_plugin_with(questionnaire)

        refute_path_exists File.join(group_dir, 'plugins.yml')
        assert_empty descriptions.for(@group)
      end

      def test_the_generated_group_file_has_the_section
        descriptions = run_plugin_with(patient_form)
        ig_metadata = build_ig_metadata(groups: [@group])
        with_config_keeper do
          InfernoSuiteGenerator::Generator::GroupGenerator.generate(ig_metadata, @dir, descriptions)
        end

        assert_includes File.read(File.join(@dir, 'patient_group.rb')), '## Used in questionnaires'
      end

      private

      def run_plugin_with(form)
        _groups, ig_resources = suite_for(@group.profile_url => profile('Patient'))
        ig_resources.add(FHIR::Questionnaire.new(form))
        run_plugin(PLUGIN_ROOT, ig_metadata: build_ig_metadata(groups: [@group]), ig_resources:, base_output_dir: @dir)
      end

      def patient_form
        questionnaire(extension: [launch_context('patient', 'Patient')],
                      item: [item('dob', 'Date of birth',
                                  expression('initialExpression', '%patient.birthDate.toString()'))])
      end

      def group_dir
        File.join(@dir, 'patient')
      end
    end
  end
end
