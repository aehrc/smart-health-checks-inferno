# frozen_string_literal: true

require 'inferno_suite_generator/core/ig_demodata'
require_relative 'shc_condition/shc_condition_patient_category_search_test'
require_relative 'shc_condition/shc_condition_patient_search_test'
require_relative 'shc_condition/shc_condition_category_search_test'
require_relative 'shc_condition/shc_condition_validation_test'
require_relative 'shc_condition/shc_condition_must_support_test'
require_relative 'shc_condition/shc_condition_reference_resolution_test'
require_relative 'shc_condition/shc_condition_create_test'
require_relative 'shc_condition/shc_condition_fhir_path_json_patch_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV040
    class ShcConditionGroup < Inferno::TestGroup
      title 'Condition Tests'
      short_description 'Verify support for the server capabilities required by the Smart Health Checks Condition.'
      description %(
  # Background

The Smart Health Checks Condition sequence verifies that the system under test is
able to provide correct responses for Condition queries. These queries
must contain resources conforming to the Smart Health Checks Condition as
specified in the Smart Health Checks v0.4.0 Implementation Guide.

# Testing Methodology
## Searching
This test sequence will first perform each required search associated
with this resource. This sequence will perform searches with the
following parameters:

* patient + category

### Search Parameters
The first search uses the selected patient(s) from the prior launch sequence. Any subsequent searches will look for its parameter values from the results of the first search. For example, the `identifier` search in the patient sequence is performed by looking for an existing `Patient.identifier` from any of the resources returned in the `_id` search. If a value cannot be found this way, the search is skipped.

### Search Validation
Inferno will retrieve up to the first 20 bundle pages of the reply for
Condition resources and save them for subsequent tests. Each of
these resources is then checked to see if it matches the searched
parameters in accordance with [FHIR search
guidelines](https://www.hl7.org/fhir/search.html). The test will fail,
for example, if a Patient search for `gender=male` returns a `female`
patient.


## Must Support
Each profile contains elements marked as "must support". This test
sequence expects to see each of these elements at least once. If at
least one cannot be found, the test will fail. The test will look
through the Condition resources found in the first test for these
elements.

## Profile Validation
Each resource returned from the first search is expected to conform to
the [Smart Health Checks Condition](https://smartforms.csiro.au/ig/StructureDefinition/SHCCondition). Each element is checked against
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

These questionnaires in the IG read or create Smart Health Checks Condition resources. The tests that make the same requests list the form items that depend on them.

- **Aboriginal and Torres Strait Islander Health Check - Medical History**: see the patch and create tests
- **Aboriginal and Torres Strait Islander Health Check**: see the search by patient + category, patch, create and Must Support tests

**Elements not checked**

The profile neither marks these elements Must Support nor requires them, so no test checks that the server returns them.

- **Aboriginal and Torres Strait Islander Health Check**
  - **verificationStatus.coding**: Recorded problems/diagnoses
  - **verificationStatus.coding.code**: Recorded problems/diagnoses


      )

      id :smart_health_checks_v040_shc_condition
      run_as_group

      def self.metadata
        @metadata ||= InfernoSuiteGenerator::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'shc_condition', 'metadata.yml'), aliases: true))
      end

      test from: :smart_health_checks_v040_shc_condition_patient_category_search_test do
        description [description, %(
**Used in questionnaires**

These questionnaires in the IG make this search. A form can pre-fill an item only if the server returns the elements the item reads. Elements marked \(not checked\) are neither Must Support nor required by the profile, so this group's tests do not check them.

- **Aboriginal and Torres Strait Islander Health Check**
  - **Query Condition**: searches Condition resources
    - Request: Condition?patient={{%patient.id}}&category=http://terminology.hl7.org/CodeSystem/condition-category|problem-list-item
    - **Recorded problems/diagnoses**: sets the population context; reads verificationStatus.coding \(not checked\), verificationStatus.coding.code \(not checked\)
    - **History of atrial fibrillation**: calculates the answer
    - **Diabetes**: calculates the answer
    - **Years since diabetes diagnosis**: calculates the answer; reads onset

        )].compact.map(&:strip).join("\n\n")
      end
      test from: :smart_health_checks_v040_shc_condition_patient_search_test
      test from: :smart_health_checks_v040_shc_condition_category_search_test
      test from: :smart_health_checks_v040_shc_condition_validation_test
      test from: :smart_health_checks_v040_shc_condition_must_support_test do
        description [description, %(
**Used in questionnaires**

Items in these questionnaires read elements of Condition that this group's tests check. A form can pre-fill an item only if the server returns the elements the item reads.

- **Aboriginal and Torres Strait Islander Health Check**
  - **onset**: Years since diabetes diagnosis

        )].compact.map(&:strip).join("\n\n")
      end
      test from: :smart_health_checks_v040_shc_condition_reference_resolution_test
      test from: :smart_health_checks_v040_shc_condition_create_test do
        description [description, %(
**Used in questionnaires**

These questionnaires in the IG create Condition resources from their answers.

- **Aboriginal and Torres Strait Islander Health Check - Medical History**
  - **Extraction template ConditionTemplate**: creates a new Condition from the answers
    - **New problems/diagnoses**: its answers fill the template
- **Aboriginal and Torres Strait Islander Health Check**
  - **Extraction template ConditionTemplate**: creates a new Condition from the answers
    - **New problems/diagnoses**: its answers fill the template

        )].compact.map(&:strip).join("\n\n")
      end
      test from: :smart_health_checks_v040_shc_condition_fhirpath_json_patch_test do
        description [description, %(
**Used in questionnaires**

These questionnaires in the IG update existing Condition resources from their answers.

- **Aboriginal and Torres Strait Islander Health Check - Medical History**
  - **Extraction template ConditionPatchTemplate**: updates an existing Condition with a FHIRPath Patch
    - **Recorded problems/diagnoses**: its answers fill the template
- **Aboriginal and Torres Strait Islander Health Check**
  - **Extraction template ConditionPatchTemplate**: updates an existing Condition with a FHIRPath Patch
    - **Recorded problems/diagnoses**: its answers fill the template

        )].compact.map(&:strip).join("\n\n")
      end
    end
  end
end
