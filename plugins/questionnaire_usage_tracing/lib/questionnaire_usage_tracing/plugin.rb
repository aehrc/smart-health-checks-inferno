# frozen_string_literal: true

module InfernoSuitePlugins
  module QuestionnaireUsageTracing
    # Entry point the host calls once it has generated its built-in tests.
    class Plugin < InfernoSuiteGenerator::Plugins::Base
      # Plugins are stateless: everything comes in through context.
      # :reek:UtilityFunction
      def generate(context)
        data_by_group = Extractor.extract(context)
        # Writes each group's data under "questionnaire_usage_tracing" in <group dir>/plugins.yml.
        context.metadata.groups(data_by_group)

        # To generate tests, add an ERB template to templates/ and a subclass of
        # InfernoSuiteGenerator::Plugins::TestGenerator, then call:
        #   MyTestGenerator.generate(context, data_by_group)
      end
    end
  end
end
