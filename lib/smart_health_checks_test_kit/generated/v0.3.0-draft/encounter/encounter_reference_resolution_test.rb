# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/reference_resolution_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class EncounterReferenceResolutionTest < Inferno::Test
      include InfernoSuiteGenerator::ReferenceResolutionTest

      title 'MustSupport references within Encounter resources are valid'
      description %(
        This test will attempt to read external references provided within elements
        marked as 'MustSupport', if any are available.

        It verifies that at least one external reference for each MustSupport Reference element
        can be accessed by the test client, and conforms to corresponding Smart Health Checks profile.

        Elements which may provide external references include:

        * Encounter.location.location
        * Encounter.participant.individual
        * Encounter.reasonReference
        * Encounter.serviceProvider
        * Encounter.subject
      )

      id :smart_health_checks_v030_draft_encounter_reference_resolution_test

      def resource_type
        'Encounter'
      end

      def self.metadata
        @metadata ||= InfernoSuiteGenerator::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true))
      end

      def scratch_resources
        scratch[:encounter_resources] ||= {}
      end

      run do
        perform_reference_resolution_test(scratch_resources[:all], { 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-patient' => 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-patient|1.1.0-preview' })
      end
    end
  end
end
