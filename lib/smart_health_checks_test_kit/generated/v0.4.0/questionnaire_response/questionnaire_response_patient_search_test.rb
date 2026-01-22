# frozen_string_literal: true

require 'inferno_suite_generator/test_modules/search_test'
require 'inferno_suite_generator/core/group_metadata'
require 'inferno_suite_generator/utils/helpers'

module SmartHealthChecksTestKit
  module SmartHealthChecksV040
    class QuestionnaireResponsePatientSearchTest < Inferno::Test
      include InfernoSuiteGenerator::SearchTest

      title '(MAY) Server returns valid results for QuestionnaireResponse search by patient'
      description %(
A server MAY support searching by
patient on the QuestionnaireResponse resource. This test
will pass if resources are returned and match the search criteria. If
none are returned, the test is skipped.

This test verifies that the server supports searching by reference using
the form `patient=[id]` as well as `patient=Patient/[id]`. The two
different forms are expected to return the same number of results. Smart Health Checks requires that both forms are supported by Smart Health Checks responders.

Because this is the first search of the sequence, resources in the
response will be used for subsequent tests.

Additionally, this test will check that GET and POST search methods
return the same number of results. Search by POST is required by the
FHIR R4 specification, and these tests interpret search by GET as a
requirement of Smart Health Checks v0.4.0.

[Smart Health Checks Server CapabilityStatement](https://smartforms.csiro.au/ig/CapabilityStatement/SHCHostFHIRServerCapabilityStatement)

      )

      id :smart_health_checks_v040_questionnaire_response_patient_search_test
      optional

      input :patient_ids,
            title: 'Patient IDs',
            description: 'Comma separated list of patient IDs that in sum contain all MUST SUPPORT elements',
            default: 'baratz-toni, irvine-ronny-lawrence, italia-sofia, howe-deangelo, hayes-arianne, baby-banks-john, banks-mia-leanne'

      def self.demodata
        @demodata ||= InfernoSuiteGenerator::Generator::IGDemodata.new(
          YAML.load_file(File.join(File.dirname(__dir__), 'demodata.yml'), aliases: true)
        )
      end

      def self.properties
        @properties ||= InfernoSuiteGenerator::SearchTestProperties.new(
          first_search: true,
          resource_type: 'QuestionnaireResponse',
          search_param_names: ['patient'],
          possible_status_search: true,
          test_reference_variants: true,
          test_post_search: true
        )
      end

      def self.metadata
        @metadata ||= InfernoSuiteGenerator::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true))
      end

      def scratch_resources
        scratch[:questionnaire_response_resources] ||= {}
      end

      run do
        run_search_test
      end
    end
  end
end
