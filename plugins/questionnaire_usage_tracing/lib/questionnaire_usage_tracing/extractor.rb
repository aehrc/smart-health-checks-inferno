# frozen_string_literal: true

module InfernoSuitePlugins
  module QuestionnaireUsageTracing
    # Collects this plugin's data for one group (group_metadata). Return nil to leave the group out.
    class Extractor < InfernoSuiteGenerator::Plugins::Extractor
      def extract
        {
          'resource' => group_metadata.resource,
          'profile_url' => group_metadata.profile_url
        }
      end
    end
  end
end
