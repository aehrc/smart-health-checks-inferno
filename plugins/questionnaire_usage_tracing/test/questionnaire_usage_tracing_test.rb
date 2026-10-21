# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'inferno_suite_generator'
require 'inferno_suite_generator/plugins/testing'

module InfernoSuitePlugins
  module QuestionnaireUsageTracing
    class PluginTest < Minitest::Test
      include InfernoSuiteGenerator::Plugins::Testing

      PLUGIN_ROOT = File.expand_path('..', __dir__)

      def test_writes_group_metadata
        Dir.mktmpdir do |dir|
          group = build_group_metadata(resource: 'Patient')

          run_plugin(PLUGIN_ROOT, ig_metadata: build_ig_metadata(groups: [group]), base_output_dir: dir)

          assert_equal 'Patient', plugin_metadata(File.join(dir, 'patient'), 'questionnaire_usage_tracing')['resource']
        end
      end
    end
  end
end
