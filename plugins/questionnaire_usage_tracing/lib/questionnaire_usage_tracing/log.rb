# frozen_string_literal: true

module InfernoSuitePlugins
  # Traces which questionnaires in the IG use each profile in the suite.
  module QuestionnaireUsageTracing
    # Prints a tracing message. Returns `nil`, so a caller can `return log(...)`.
    def self.log(message)
      puts "Questionnaire usage tracing: #{message}"
      nil
    end
  end
end
