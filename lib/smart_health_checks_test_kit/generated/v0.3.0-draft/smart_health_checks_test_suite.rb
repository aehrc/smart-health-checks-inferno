# frozen_string_literal: true

require 'base64'
require 'inferno/dsl/oauth_credentials'
require 'inferno_suite_generator/utils/helpers'
require_relative '../../version'

require_relative 'patient_group'
require_relative 'shc_blood_pressure_group'
require_relative 'shc_body_height_group'
require_relative 'shc_body_weight_group'
require_relative 'shc_pathology_result_group'
require_relative 'shc_head_circumference_group'
require_relative 'shc_heart_rate_group'
require_relative 'shc_heart_rhythm_group'
require_relative 'shc_waist_circumference_group'
require_relative 'shc_smoking_status_group'
require_relative 'allergy_intolerance_group'
require_relative 'shc_condition_group'
require_relative 'immunization_group'
require_relative 'medication_statement_group'
require_relative 'questionnaire_response_group'
require_relative 'encounter_group'
require_relative 'practitioner_group'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class SmartHealthChecksTestSuite < Inferno::TestSuite
      title 'Smart Health Checks v0.3.0-draft'
      description %(
        The Smart Health Checks Test Kit tests systems for their conformance to the [Smart Health Checks Implementation Guide](https://build.fhir.org/ig/aehrc/smart-forms-ig/index.html).

        HL7® FHIR® resources are validated with the Java validator using
        https://tx.dev.hl7.org.au/fhir as the terminology server.
      )
      version VERSION

      VERSION_SPECIFIC_MESSAGE_FILTERS = [].freeze

      def self.metadata
        @metadata ||= YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true)[:groups].map do |raw_metadata|
          Generator::GroupMetadata.new(raw_metadata)
        end
      end

      fhir_resource_validator do
        igs 'csiro.fhir.au.smartforms#0.3.0-draft'
        message_filters = [
          "The value provided ('xml') was not found in the value set 'MimeType'",
          "The value provided ('json') was not found in the value set 'MimeType'",
          "The value provided ('ttl') was not found in the value set 'MimeType'"
        ] + VERSION_SPECIFIC_MESSAGE_FILTERS

        cli_context do
          txServer ENV.fetch('TX_SERVER_URL', 'https://tx.dev.hl7.org.au/fhir')
          disableDefaultResourceFetcher false
        end

        exclude_message do |message|
          Helpers.is_message_exist_in_list(message_filters, message.message)
        end

        perform_additional_validation do |resource, _profile_url|
          ProvenanceValidator.validate(resource) if resource.instance_of?(FHIR::Provenance)
        end
      end

      links [
        {
          label: 'Report Issue',
          url: 'https://github.com/aehrc/smart-health-checks-inferno/issues'
        },
        {
          label: 'Source Code',
          url: 'https://github.com/aehrc/smart-health-checks-inferno'
        },
        {
          label: 'Implementation Guide',
          url: 'https://build.fhir.org/ig/aehrc/smart-forms-ig/index.html'
        }
      ]

      id :smart_health_checks_v030_draft

      input :url,
            title: 'FHIR Endpoint',
            description: 'URL of the FHIR endpoint',
            default: ''
      input :smart_credentials,
            title: 'OAuth Credentials',
            type: :oauth_credentials,
            optional: true
      input :header_name,
            title: 'Header name',
            optional: true
      input :header_value,
            title: 'Header value',
            optional: true

      fhir_client do
        url :url
        oauth_credentials :smart_credentials
        headers Helpers.get_http_header(header_name, header_value)
      end

      group do
        title 'Smart Health Checks FHIR API'
        id :smart_health_checks_v030_draft_fhir_api

        group from: :smart_health_checks_v030_draft_patient

        group from: :smart_health_checks_v030_draft_shc_blood_pressure

        group from: :smart_health_checks_v030_draft_shc_body_height

        group from: :smart_health_checks_v030_draft_shc_body_weight

        group from: :smart_health_checks_v030_draft_shc_pathology_result

        group from: :smart_health_checks_v030_draft_shc_head_circumference

        group from: :smart_health_checks_v030_draft_shc_heart_rate

        group from: :smart_health_checks_v030_draft_shc_heart_rhythm

        group from: :smart_health_checks_v030_draft_shc_waist_circumference

        group from: :smart_health_checks_v030_draft_shc_smoking_status

        group from: :smart_health_checks_v030_draft_allergy_intolerance

        group from: :smart_health_checks_v030_draft_shc_condition

        group from: :smart_health_checks_v030_draft_immunization

        group from: :smart_health_checks_v030_draft_medication_statement

        group from: :smart_health_checks_v030_draft_questionnaire_response

        group from: :smart_health_checks_v030_draft_encounter

        group from: :smart_health_checks_v030_draft_practitioner
      end
    end
  end
end
