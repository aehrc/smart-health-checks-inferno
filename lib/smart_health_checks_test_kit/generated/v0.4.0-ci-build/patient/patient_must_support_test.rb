# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/must_support_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV040_CI_BUILD
    class PatientMustSupportTest < Inferno::Test
      include InfernoSuiteGenerator::MustSupportTest

      title 'All must support elements are provided in the Patient resources returned'
      description %(
        Smart Health Checks Responders SHALL be capable of populating all data elements as
        part of the query results as specified by the Smart Health Checks Server Capability
        Statement. This test will look through the Patient resources
        found previously for the following must support elements:

        * Patient.address
        * Patient.address.city
        * Patient.address.line
        * Patient.address.postalCode
        * Patient.address.state
        * Patient.address.type
        * Patient.address.use
        * Patient.birthDate
        * Patient.communication
        * Patient.communication.language
        * Patient.communication.preferred
        * Patient.contact
        * Patient.contact.name
        * Patient.contact.name.family
        * Patient.contact.name.given
        * Patient.contact.name.prefix
        * Patient.contact.relationship
        * Patient.contact.telecom
        * Patient.extension:closingTheGapRegistration
        * Patient.extension:genderIdentity
        * Patient.extension:indigenousStatus
        * Patient.extension:individualPronouns
        * Patient.extension:recordedSexOrGender
        * Patient.gender
        * Patient.identifier
        * Patient.name
        * Patient.name.family
        * Patient.name.given
        * Patient.name.prefix
        * Patient.name.text
        * Patient.name.use
        * Patient.telecom
        * Patient.telecom.system
        * Patient.telecom.use
        * Patient.telecom.value
      )

      id :smart_health_checks_v040_ci_build_patient_must_support_test

      def resource_type
        'Patient'
      end

      def self.metadata
        @metadata ||= InfernoSuiteGenerator::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true))
      end

      def scratch_resources
        scratch[:patient_resources] ||= {}
      end

      run do
        perform_must_support_test(all_scratch_resources)
      end
    end
  end
end
