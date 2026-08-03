# frozen_string_literal: true

require 'base64'
require 'inferno/dsl/oauth_credentials'
require 'inferno_suite_generator/utils/helpers'
require_relative '../../version'
require_relative '../../outer_groups/teardown'

require_relative '../../ext/fhir_client_request_patch_payload'
require_relative '../../ext/crud'
require_relative '../../ext/patch_format'

require_relative 'patient_group'
require_relative 'allergy_intolerance_group'
require_relative 'shc_condition_group'
require_relative 'immunization_group'
require_relative 'medication_statement_group'
require_relative 'shc_blood_pressure_group'
require_relative 'shc_body_height_group'
require_relative 'shc_body_weight_group'
require_relative 'shc_head_circumference_group'
require_relative 'shc_heart_rate_group'
require_relative 'shc_heart_rhythm_group'
require_relative 'shc_pathology_result_group'
require_relative 'shc_smoking_status_group'
require_relative 'shc_waist_circumference_group'
require_relative 'questionnaire_response_group'
require_relative 'encounter_group'
require_relative 'practitioner_group'

module SmartHealthChecksTestKit
  module SmartHealthChecksV040
    class SmartHealthChecksTestSuite < Inferno::TestSuite
      title 'Smart Health Checks v0.4.0'
      description %(
        The Smart Health Checks Test Kit tests systems for their conformance to the [Smart Health Checks Implementation Guide](https://smartforms.csiro.au/ig/0.4.0/index.html).

        HL7® FHIR® resources are validated with the Java validator using
        https://tx.dev.hl7.org.au/fhir as the terminology server.

        The test suite is generated using the [InfernoSuiteGenerator](https://github.com/hl7au/inferno_suite_generator) gem version 0.1.0.
      )
      version VERSION

      # `id` MUST be declared before `fhir_resource_validator`. The validator captures the
      # suite id eagerly as its `test_suite_id`, and Inferno keys validator sessions on it.
      # If `id` comes after, the capture falls back to the base-class name
      # "Inferno::Entities::TestSuite", which every affected suite then shares as a single
      # validator session, collapsing separate IG versions onto one validator engine and
      # causing intermittent "Unable to resolve profile ...|<version>" errors.
      id :smart_health_checks_v040

      VERSION_SPECIFIC_MESSAGE_FILTERS = [].freeze

      def self.metadata
        @metadata ||= YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true)[:groups].map do |raw_metadata|
          Generator::GroupMetadata.new(raw_metadata)
        end
      end

      fhir_resource_validator do
        igs '/home/igs/0.4.0-3f0c.tgz'
        message_filters = [
          "The value provided ('xml') was not found in the value set 'MimeType'",
          "The value provided ('json') was not found in the value set 'MimeType'",
          "The value provided ('ttl') was not found in the value set 'MimeType'",
          # hl7.fhir.uv.sdc#4.0.0 depends on hl7.fhir.uv.xver-r5.r4#0.1.0, which ships
          # the R5 (5.0.0) CodeSystem for medication-statement-status under the same
          # canonical URL as the R4 one. The validator resolves that copy in preference
          # to hl7.fhir.r4.core#4.0.1 and then reports every valid R4 status code
          # ('active', 'completed', 'stopped', 'on-hold') as unknown, because R5 replaced
          # them with 'recorded', 'entered-in-error' and 'draft'. Validating the same
          # resource against R4 core alone resolves 4.0.1 and reports no error.
          #
          # Scoped to the 5.0.0 version string so genuine R4 status errors, which report
          # version 4.0.1, are still surfaced. Remove once the validator stops preferring
          # cross-version CodeSystems over the target FHIR version's own definitions.
          "in the CodeSystem 'http://hl7.org/fhir/CodeSystem/medication-statement-status' version '5.0.0'"
        ] + VERSION_SPECIFIC_MESSAGE_FILTERS

        cli_context do
          txServer ENV.fetch('TX_SERVER_URL', 'https://tx.dev.hl7.org.au/fhir')
          # Select the SNOMED CT-AU edition. The validator otherwise defaults to the
          # International edition (900000000000207008), which tx.dev.hl7.org.au does
          # not carry, so every unversioned http://snomed.info/sct reference fails to
          # resolve ("version 'null' could not be found") and value set membership
          # then degrades to "none of the codings are in the value set" even for value
          # sets that enumerate the code explicitly.
          #
          # Pinned to the edition/module without a date so the terminology server keeps
          # supplying its own current version. Pinning a dated version would go stale
          # every time tx.dev publishes a new release.
          snomedCT ENV.fetch('SNOMED_EDITION', '32506021000036107')
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

      input :url,
            title: 'FHIR Endpoint',
            description: 'URL of the FHIR endpoint',
            default: 'https://proxy.smartforms.io/fhir'
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

      input :extra_bundle,
            title: 'Extra Transaction Bundle',
            description: 'A FHIR Bundle containing resources to be included as patch requests in the test suite.',
            type: 'textarea',
            optional: true

      fhir_client do
        url :url
        oauth_credentials :smart_credentials
        headers Helpers.get_http_header(header_name, header_value)
      end

      group do
        title 'Smart Health Checks FHIR API'
        id :smart_health_checks_v040_fhir_api

        group from: :smart_health_checks_v040_patient

        group from: :smart_health_checks_v040_allergy_intolerance

        group from: :smart_health_checks_v040_shc_condition

        group from: :smart_health_checks_v040_immunization

        group from: :smart_health_checks_v040_medication_statement

        group from: :smart_health_checks_v040_shc_blood_pressure

        group from: :smart_health_checks_v040_shc_body_height

        group from: :smart_health_checks_v040_shc_body_weight

        group from: :smart_health_checks_v040_shc_head_circumference

        group from: :smart_health_checks_v040_shc_heart_rate

        group from: :smart_health_checks_v040_shc_heart_rhythm

        group from: :smart_health_checks_v040_shc_pathology_result

        group from: :smart_health_checks_v040_shc_smoking_status

        group from: :smart_health_checks_v040_shc_waist_circumference

        group from: :smart_health_checks_v040_questionnaire_response

        group from: :smart_health_checks_v040_encounter

        group from: :smart_health_checks_v040_practitioner

        group from: :smart_health_checks_v030_draft_teardown
      end
    end
  end
end
