# frozen_string_literal: true

require 'inferno_suite_generator/utils/helpers'
require 'inferno_suite_generator/utils/references_keeper'

module SmartHealthChecksTestKit
  module SmartHealthChecksV030_DRAFT
    class TeardownGroup < Inferno::TestGroup
      SUCCESS_STATUSES = [200, 202, 204].freeze

      id :smart_health_checks_v030_draft_teardown
      title 'Teardown Service'
      short_description 'Service to clean up test resources after test execution.'
      description %(
# Service Purpose

This teardown service provides cleanup functionality to remove test resources
that were created during the Smart Health Checks test suite execution. Since
Inferno does not have a built-in teardown mechanism, this service is implemented
as a test group to provide the necessary cleanup operations.

# Operation

The service identifies resources marked for deletion and performs cleanup
operations to maintain a clean testing environment and prevent resource
accumulation on the test server.
      )
      run_as_group

      test do
        id :smart_health_checks_v030_draft_teardown_resources
        title 'Resource cleanup service'
        description %(
This service operation deletes test resources that were created during the
test suite execution. It processes candidate resources from the test session
and performs DELETE operations on the FHIR server to clean up the test
environment.

The service groups resources by type and processes deletions systematically,
logging progress and results for monitoring purposes.
        )

        run do
          info "Delete ReferencesKeeper instance with url #{url}"
          info "ReferencesKeeper instances: #{InfernoSuiteGenerator::ReferencesKeeper.entities.count}"
          InfernoSuiteGenerator::ReferencesKeeper.destroy_instance(url)
          info "ReferencesKeeper instances: #{InfernoSuiteGenerator::ReferencesKeeper.entities.count}"
          candidates = scratch[:teardown_candidates] ||= []
          resource_types = candidates.map(&:resourceType).uniq
          info "Found #{candidates.length} resources to delete..."
          resource_types.each do |resource_type|
            filtered_candidates = candidates.select { |candidate| candidate.resourceType == resource_type }
            info "Starting to delete #{filtered_candidates.length} #{resource_type} resources..."
            filtered_candidates.each do |candidate|
              fhir_delete(resource_type, candidate.id)
              if SUCCESS_STATUSES.include? response[:status]
                info "Successfully deleted #{resource_type} resource with id #{candidate.id}"
              else
                error "Failed to delete #{resource_type} resource with id #{candidate.id}"
                break
              end
            end
          end
        end
      end
    end
  end
end
