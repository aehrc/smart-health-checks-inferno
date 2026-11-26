# frozen_string_literal: true

require 'inferno_suite_generator/core/ig_demodata'
require_relative 'patient/patient_read_test'
require_relative 'patient/patient_validation_test'
require_relative 'patient/patient_must_support_test'

module SmartHealthChecksTestKit
  module SmartHealthChecksV040
    class PatientGroup < Inferno::TestGroup
      title 'Patient Tests'
      short_description 'Verify support for the server capabilities required by the Smart Health Checks Patient.'
      description %(
  # Background

The Smart Health Checks Patient sequence verifies that the system under test is
able to provide correct responses for Patient queries. These queries
must contain resources conforming to the Smart Health Checks Patient as
specified in the Smart Health Checks v0.4.0 Implementation Guide.

# Testing Methodology


## Must Support
Each profile contains elements marked as "must support". This test
sequence expects to see each of these elements at least once. If at
least one cannot be found, the test will fail. The test will look
through the Patient resources found in the first test for these
elements.

## Profile Validation
Each resource returned from the first search is expected to conform to
the [Smart Health Checks Patient](https://smartforms.csiro.au/ig/StructureDefinition/SHCPatient). Each element is checked against
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

These questionnaires in the IG read or create Smart Health Checks Patient resources. The tests that make the same requests list the form items that depend on them.

- **Aboriginal and Torres Strait Islander Health Check - Absolute Cardiovascular Disease Risk Calculation**: see the read and Must Support tests
- **Aboriginal and Torres Strait Islander Health Check - Examination**: see the read and Must Support tests
- **Aboriginal and Torres Strait Islander Health Check - Patient Details**: see the read and Must Support tests
- **Aboriginal and Torres Strait Islander Health Check**: see the read and Must Support tests

**Elements not checked**

The profile neither marks these elements Must Support nor requires them, so no test checks that the server returns them.

- **Aboriginal and Torres Strait Islander Health Check - Patient Details** and **Aboriginal and Torres Strait Islander Health Check**
  - **Preferred pronouns**: individualPronouns extension: value.coding, period.end
  - **Gender identity**: genderIdentity extension: value.coding, period.end
  - **Emergency contact**: contact.relationship.coding.code
  - **Medicare number**: identifier.type.coding: system, code
  - **Pensioner Card Number**, **Health Care Card Number**: identifier: value, type.coding.system, type.coding.code
- Only in **Aboriginal and Torres Strait Islander Health Check**
  - **Sex assigned at birth**: recordedSexOrGender extension: value.coding, type.coding.code, effectivePeriod.end


      )

      id :smart_health_checks_v040_patient
      run_as_group

      def self.metadata
        @metadata ||= InfernoSuiteGenerator::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'patient', 'metadata.yml'), aliases: true))
      end

      test from: :smart_health_checks_v040_patient_read_test do
        description [description, %(
**Used in questionnaires**

These questionnaires in the IG read Patient resources as this test does: by id, or as the resource a form is opened for. A form can pre-fill an item only if the server returns the elements the item reads. Elements marked \(not checked\) are neither Must Support nor required by the profile, so this group's tests do not check them.

- **Aboriginal and Torres Strait Islander Health Check - Absolute Cardiovascular Disease Risk Calculation**
  - **Launch context patient**: the Patient the form is opened for
    - **Height**: calculates the answer; reads birthDate
- **Aboriginal and Torres Strait Islander Health Check - Examination**
  - **Launch context patient**: the Patient the form is opened for
    - **New result**: calculates the answer; reads birthDate
- **Aboriginal and Torres Strait Islander Health Check - Patient Details**
  - **Launch context patient**: the Patient the form is opened for
    - **Name**: pre-fills the answer; reads name, name.use, name.family, name.given, name.prefix, name.text
    - **Preferred name**: pre-fills the answer; reads name, name.use, name.family, name.given, name.prefix, name.text
    - **Preferred pronouns**: pre-fills the answer; reads extension:individualPronouns.extension[value].value.coding \(not checked\), extension:individualPronouns.extension[period].value.end \(not checked\)
    - **Gender identity**: pre-fills the answer; reads extension:genderIdentity.extension[value].value.coding \(not checked\), extension:genderIdentity.extension[period].value.end \(not checked\)
    - **Administrative gender**: pre-fills the answer; reads gender
    - **Date of birth**: pre-fills the answer; reads birthDate
    - **Age**: pre-fills the answer; reads birthDate
    - **Aboriginal and/or Torres Strait Islander status**: pre-fills the answer; reads extension:indigenousStatus.value
    - **Home address**: sets the population context; reads address, address.use, address.type
    - **Postal address**: sets the population context, shows or hides the item; reads address, address.type
    - **Home phone**: pre-fills the answer; reads telecom.value, telecom.system, telecom.use
    - **Mobile phone**: pre-fills the answer; reads telecom.value, telecom.system, telecom.use
    - **Emergency contact**: sets the population context; reads contact, contact.relationship.coding \(not checked\), contact.relationship.coding.code \(not checked\)
    - **Medicare number**: sets the population context; reads identifier, identifier.type.coding \(not checked\), identifier.type.coding.system \(not checked\), identifier.type.coding.code \(not checked\)
    - **Pensioner Card Number**: pre-fills the answer; reads identifier.value \(not checked\), identifier.type.coding \(not checked\), identifier.type.coding.system \(not checked\), identifier.type.coding.code \(not checked\)
    - **Health Care Card Number**: pre-fills the answer; reads identifier.value \(not checked\), identifier.type.coding \(not checked\), identifier.type.coding.system \(not checked\), identifier.type.coding.code \(not checked\)
    - **Registered for Closing the Gap PBS Co-payment Measure \(CTG\)**: pre-fills the answer; reads extension:closingTheGapRegistration.value
- **Aboriginal and Torres Strait Islander Health Check**
  - **Launch context patient**: the Patient the form is opened for
    - **Name**: pre-fills the answer; reads name, name.use, name.family, name.given, name.prefix, name.text
    - **Preferred name**: pre-fills the answer; reads name, name.use, name.family, name.given, name.prefix, name.text
    - **Preferred pronouns**: pre-fills the answer; reads extension:individualPronouns.extension[value].value.coding \(not checked\), extension:individualPronouns.extension[period].value.end \(not checked\)
    - **Gender identity**: pre-fills the answer; reads extension:genderIdentity.extension[value].value.coding \(not checked\), extension:genderIdentity.extension[period].value.end \(not checked\)
    - **Administrative gender**: pre-fills the answer; reads gender
    - **Sex assigned at birth**: pre-fills the answer; reads extension:recordedSexOrGender.extension[value].value.coding \(not checked\), extension:recordedSexOrGender.extension[type] \(not checked\), extension:recordedSexOrGender.extension[type].value.coding.code \(not checked\), extension:recordedSexOrGender.extension[effectivePeriod].value.end \(not checked\)
    - **Date of birth**: pre-fills the answer; reads birthDate
    - **Age**: pre-fills the answer; reads birthDate
    - **Aboriginal and/or Torres Strait Islander status**: pre-fills the answer; reads extension:indigenousStatus.value
    - **Home address**: sets the population context; reads address, address.use, address.type
    - **Postal address**: sets the population context, shows or hides the item; reads address, address.type
    - **Home phone**: pre-fills the answer; reads telecom.value, telecom.system, telecom.use
    - **Mobile phone**: pre-fills the answer; reads telecom.value, telecom.system, telecom.use
    - **Emergency contact**: sets the population context; reads contact, contact.relationship.coding \(not checked\), contact.relationship.coding.code \(not checked\)
    - **Medicare number**: sets the population context; reads identifier, identifier.type.coding \(not checked\), identifier.type.coding.system \(not checked\), identifier.type.coding.code \(not checked\)
    - **Pensioner Card Number**: pre-fills the answer; reads identifier.value \(not checked\), identifier.type.coding \(not checked\), identifier.type.coding.system \(not checked\), identifier.type.coding.code \(not checked\)
    - **Health Care Card Number**: pre-fills the answer; reads identifier.value \(not checked\), identifier.type.coding \(not checked\), identifier.type.coding.system \(not checked\), identifier.type.coding.code \(not checked\)
    - **Registered for Closing the Gap PBS Co-payment Measure \(CTG\)**: pre-fills the answer; reads extension:closingTheGapRegistration.value
    - **New result**: calculates the answer; reads birthDate
    - **Height**: calculates the answer; reads birthDate

        )].compact.map(&:strip).join("\n\n")
      end
      test from: :smart_health_checks_v040_patient_validation_test
      test from: :smart_health_checks_v040_patient_must_support_test do
        description [description, %(
**Used in questionnaires**

Items in these questionnaires read elements of Patient that this group's tests check. A form can pre-fill an item only if the server returns the elements the item reads.

- **Aboriginal and Torres Strait Islander Health Check - Absolute Cardiovascular Disease Risk Calculation** and **Aboriginal and Torres Strait Islander Health Check**
  - **Height**: birthDate
- **Aboriginal and Torres Strait Islander Health Check - Examination** and **Aboriginal and Torres Strait Islander Health Check**
  - **New result**: birthDate
- **Aboriginal and Torres Strait Islander Health Check - Patient Details** and **Aboriginal and Torres Strait Islander Health Check**
  - **Name**, **Preferred name**: name: use, family, given, prefix, text
  - **Administrative gender**: gender
  - **Date of birth**, **Age**: birthDate
  - **Aboriginal and/or Torres Strait Islander status**: indigenousStatus extension
  - **Home address**: address: use, type
  - **Postal address**: address.type
  - **Home phone**, **Mobile phone**: telecom: value, system, use
  - **Emergency contact**: contact
  - **Medicare number**: identifier
  - **Registered for Closing the Gap PBS Co-payment Measure \(CTG\)**: closingTheGapRegistration extension

        )].compact.map(&:strip).join("\n\n")
      end
    end
  end
end
