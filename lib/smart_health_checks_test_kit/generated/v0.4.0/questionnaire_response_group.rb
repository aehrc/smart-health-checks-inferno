# frozen_string_literal: true

require 'inferno_suite_generator/core/ig_demodata'
require_relative 'questionnaire_response/questionnaire_response_patient_search_test'
require_relative 'questionnaire_response/questionnaire_response_questionnaire_search_test'
require_relative 'questionnaire_response/questionnaire_response_status_search_test'
require_relative 'questionnaire_response/questionnaire_response_patient_questionnaire_search_test'
require_relative 'questionnaire_response/questionnaire_response_patient_status_search_test'
require_relative 'questionnaire_response/questionnaire_response_read_test'
require_relative 'questionnaire_response/questionnaire_response_validation_test'
require_relative 'questionnaire_response/questionnaire_response_must_support_test'
require_relative 'questionnaire_response/questionnaire_response_reference_resolution_test'
require_relative 'questionnaire_response/questionnaire_response_create_test'
require_relative 'questionnaire_response/questionnaire_response_update_update_test'
require_relative 'questionnaire_response/questionnaire_response_update_create_update_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV040
    class QuestionnaireResponseGroup < Inferno::TestGroup
      title 'Questionnaire Response Tests'
      short_description 'Verify support for the server capabilities required by the Smart Health Checks Questionnaire Response.'
      description %(
  # Background

The Smart Health Checks Questionnaire Response sequence verifies that the system under test is
able to provide correct responses for QuestionnaireResponse queries. These queries
must contain resources conforming to the Smart Health Checks Questionnaire Response as
specified in the Smart Health Checks v0.4.0 Implementation Guide.

# Testing Methodology
## Searching
This test sequence will first perform each required search associated
with this resource. This sequence will perform searches with the
following parameters:

* patient + questionnaire
* patient + status

### Search Parameters
The first search uses the selected patient(s) from the prior launch sequence. Any subsequent searches will look for its parameter values from the results of the first search. For example, the `identifier` search in the patient sequence is performed by looking for an existing `Patient.identifier` from any of the resources returned in the `_id` search. If a value cannot be found this way, the search is skipped.

### Search Validation
Inferno will retrieve up to the first 20 bundle pages of the reply for
QuestionnaireResponse resources and save them for subsequent tests. Each of
these resources is then checked to see if it matches the searched
parameters in accordance with [FHIR search
guidelines](https://www.hl7.org/fhir/search.html). The test will fail,
for example, if a Patient search for `gender=male` returns a `female`
patient.


## Must Support
Each profile contains elements marked as "must support". This test
sequence expects to see each of these elements at least once. If at
least one cannot be found, the test will fail. The test will look
through the QuestionnaireResponse resources found in the first test for these
elements.

## Profile Validation
Each resource returned from the first search is expected to conform to
the [Smart Health Checks Questionnaire Response](https://smartforms.csiro.au/ig/StructureDefinition/SHCQuestionnaireResponse). Each element is checked against
teminology binding and cardinality requirements.

Elements with a required binding are validated against their bound
ValueSet. If the code/system in the element is not part of the ValueSet,
then the test will fail.

## Reference Validation
At least one instance of each external reference in elements marked as
"must support" within the resources provided by the system must resolve.
The test will attempt to read each reference found and will fail if no
read succeeds.

**Used in questionnaires**

These questionnaires in the IG read or create Smart Health Checks Questionnaire Response resources. The tests that make the same requests list the form items that depend on them.

- **Aboriginal and Torres Strait Islander Health Check - About The Health Check**: see the search by patient + questionnaire and Must Support tests
- **Aboriginal and Torres Strait Islander Health Check**: see the search by patient + questionnaire and Must Support tests

**Not tested by this group**

No test in this group makes these requests or writes these resources, so nothing checks what these forms get from them.

- **Aboriginal and Torres Strait Islander Health Check - About The Health Check**
  - **Query QuestionnaireResponseLatestCompleted**: searches QuestionnaireResponse resources
    - Request: QuestionnaireResponse?questionnaire=http://www.health.gov.au/assessments/mbs/715&status=completed&_count=1&_sort=-authored&patient={{%patient.id}}
    - A search by questionnaire + status + patient; this group tests patient, questionnaire, status, patient + questionnaire, patient + status
    - **Date of last completed health check**: pre-fills the answer; reads authored
- **Aboriginal and Torres Strait Islander Health Check**
  - **Query QuestionnaireResponseLatestCompleted**: searches QuestionnaireResponse resources
    - Request: QuestionnaireResponse?questionnaire=http://www.health.gov.au/assessments/mbs/715&status=completed&_count=1&_sort=-authored&patient={{%patient.id}}
    - A search by questionnaire + status + patient; this group tests patient, questionnaire, status, patient + questionnaire, patient + status
    - **Date of last completed health check**: pre-fills the answer; reads authored


      )

      id :smart_health_checks_v040_questionnaire_response
      run_as_group

      def self.metadata
        @metadata ||= InfernoSuiteGenerator::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'questionnaire_response', 'metadata.yml'), aliases: true))
      end

      test from: :smart_health_checks_v040_questionnaire_response_patient_search_test
      test from: :smart_health_checks_v040_questionnaire_response_questionnaire_search_test
      test from: :smart_health_checks_v040_questionnaire_response_status_search_test
      test from: :smart_health_checks_v040_questionnaire_response_patient_questionnaire_search_test do
        description [description, %(
**Used in questionnaires**

These questionnaires in the IG make this search. A form can pre-fill an item only if the server returns the elements the item reads. Elements marked \(not checked\) are neither Must Support nor required by the profile, so this group's tests do not check them.

- **Aboriginal and Torres Strait Islander Health Check - About The Health Check**
  - **Query QuestionnaireResponseLatest**: searches QuestionnaireResponse resources
    - Request: QuestionnaireResponse?questionnaire=http://www.health.gov.au/assessments/mbs/715&_count=1&_sort=-authored&patient={{%patient.id}}
    - **Health check already in progress?**: pre-fills the answer; reads status
- **Aboriginal and Torres Strait Islander Health Check**
  - **Query QuestionnaireResponseLatest**: searches QuestionnaireResponse resources
    - Request: QuestionnaireResponse?questionnaire=http://www.health.gov.au/assessments/mbs/715&_count=1&_sort=-authored&patient={{%patient.id}}
    - **Health check already in progress?**: pre-fills the answer; reads status

        )].compact.map(&:strip).join("\n\n")
      end
      test from: :smart_health_checks_v040_questionnaire_response_patient_status_search_test
      test from: :smart_health_checks_v040_questionnaire_response_read_test
      test from: :smart_health_checks_v040_questionnaire_response_validation_test
      test from: :smart_health_checks_v040_questionnaire_response_must_support_test do
        description [description, %(
**Used in questionnaires**

Items in these questionnaires read elements of QuestionnaireResponse that this group's tests check. A form can pre-fill an item only if the server returns the elements the item reads.

- **Aboriginal and Torres Strait Islander Health Check - About The Health Check** and **Aboriginal and Torres Strait Islander Health Check**
  - **Date of last completed health check**: authored
  - **Health check already in progress?**: status

        )].compact.map(&:strip).join("\n\n")
      end
      test from: :smart_health_checks_v040_questionnaire_response_reference_resolution_test
      test from: :smart_health_checks_v040_questionnaire_response_create_test
      test from: :smart_health_checks_v040_questionnaire_response_update_update_test
      test from: :smart_health_checks_v040_questionnaire_response_update_new_update_test
    end
  end
end
