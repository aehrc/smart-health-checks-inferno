# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/reference_resolution_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class AllergyIntoleranceReferenceResolutionTest < Inferno::Test
      include InfernoSuiteGenerator::ReferenceResolutionTest

      title 'MustSupport references within AllergyIntolerance resources are valid'
      description %(
        This test will attempt to read external references provided within elements
        marked as 'MustSupport', if any are available.

        It verifies that at least one external reference for each MustSupport Reference element
        can be accessed by the test client, and conforms to corresponding Smart Health Checks profile.

        Elements which may provide external references include:

        * AllergyIntolerance.patient
      )

      id :smart_health_checks_v030_draft_allergy_intolerance_reference_resolution_test

      def resource_type
        'AllergyIntolerance'
      end

      def self.metadata
        @metadata ||= InfernoSuiteGenerator::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true))
      end

      def scratch_resources
        scratch[:allergy_intolerance_resources] ||= {}
      end

      run do
        perform_reference_resolution_test(scratch_resources[:all], { 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-patient' => 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-patient|1.1.0-preview', 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-encounter' => 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-encounter|1.1.0-preview', 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-location' => 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-location|1.1.0-preview', 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-practitioner' => 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-practitioner|1.1.0-preview', 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-practitionerrole' => 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-practitionerrole|1.1.0-preview', 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-organization' => 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-organization|1.1.0-preview', 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-relatedperson' => 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-relatedperson|1.1.0-preview' })
      end
    end
  end
end
