# frozen_string_literal: true

module InfernoSuitePlugins
  module QuestionnaireUsageTracing
    # Traces every Questionnaire in the IG over the suite's groups and writes each traced group's entries
    # under "questionnaire_usage_tracing" in <group dir>/plugins.yml.
    class Plugin < InfernoSuiteGenerator::Plugins::Base
      def generate(context)
        traces = Tracer.new(context.ig_resources, context.groups).trace
        context.groups.each do |group|
          entries = traces[group.profile_url]
          context.metadata.group(group, entries:) if entries
        end
      end
    end
  end
end
