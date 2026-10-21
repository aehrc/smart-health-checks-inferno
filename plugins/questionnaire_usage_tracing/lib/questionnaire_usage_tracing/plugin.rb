# frozen_string_literal: true

module InfernoSuitePlugins
  module QuestionnaireUsageTracing
    # Traces every Questionnaire in the IG over the suite's groups. Each traced group gets its entries under
    # "questionnaire_usage_tracing" in <group dir>/plugins.yml, and a "Used in questionnaires" section at the
    # end of its description.
    class Plugin < InfernoSuiteGenerator::Plugins::Base
      def generate(context)
        traces = Tracer.new(context.ig_resources, context.groups).trace
        context.groups.each do |group|
          entries = traces[group.profile_url]
          next unless entries

          context.metadata.group(group, entries:)
          section = UsageSection.new(entries, group)
          context.descriptions.group(group, section.markdown) unless section.empty?
        end
      end
    end
  end
end
