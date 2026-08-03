# SHC 0.4.0 validation findings: what is real, what is ours

Categorisation of every message produced by a full suite run against the
Smart Health Checks 0.4.0 test kit, run on the HL7 validator with the
SNOMED CT-AU edition fix in place.

- **Run**: `kt9QS5xPH5C` on `inferno-next.smartforms.io`, 2026-07-30
- **Target**: `https://proxy.smartforms.io/fhir`, patients `pat-sf` and `baby-smith-john`
- **Result**: 113 pass, 8 fail, 14 skip
- **Messages**: 1057 total (32 error, 251 warning, 774 info)

Every terminology claim below was checked directly against
`tx.dev.hl7.org.au` rather than taken on the validator's word.

## Summary

| Category | Messages | Share |
| --- | ---: | ---: |
| Test kit noise or defect | 316 | 30% |
| Correct but unactionable (upstream status flags, best practice) | 440 | 42% |
| Genuine finding: test data or IG must change | 208 | 20% |
| Validator or terminology server gap | 8 | 1% |
| Uncategorised remainder | 85 | 8% |

The headline: **only 4 distinct genuine defects produce all 32 errors**, and
28% of the entire report is the test kit narrating its own bookkeeping.

### All 251 warnings, adjudicated

Errors alone are not the interesting part of this run, so every warning was
categorised too, not just the failures.

| Warning class | Count | Verdict |
| --- | ---: | --- |
| `dom-6`: resource should have narrative | 86 | Genuine, fixture |
| In general, all observations should have a performer | 71 | Correct, best practice, unactionable |
| `meta.profile` reference could not be found | 44 | **Genuine, and the profile claim goes unchecked** |
| `NPI` not in `identifier-type` | 21 | Genuine, fixture |
| Found multiple matching identifier profiles | 6 | Informational |
| MIMS / PBS code system unresolvable | 6 | Validator gap, correctly disclosed |
| SNOMED code not in `observation-vitalsignresult` | 5 + 4 | Upstream: the value set is LOINC-only |
| Waist circumference not a FHIR vital sign | 5 | Upstream AU Core / FHIR tension |
| **Wrong display name** (`Body Weight` vs `Body weight`) | 2 | **Genuine, fixture** |
| Inactive SNOMED concept | 1 | Genuine, fixture |
| SPIA pathology value set miss | 1 | Genuine, fixture |
| ICD-11 unvalidatable | 1 | Validator / terminology gap |

Two classes worth pulling out because they are easy to dismiss:

**Wrong display name.** `Observation/bodyweight-mcc` sends
`display = "Body Weight"` for LOINC `29463-7`. Verified: `result = false`,
the correct display is `Body weight`, lowercase w. A real fixture defect.
This is also the class that used to be reported as an **error** before the
platform downgraded display mismatches to warnings, which is why the
`displayWarnings` change mattered: the finding is still visible, it just no
longer fails a group on a capitalisation difference.

**SNOMED codes in vital-signs slots.** `Observation.code` on heart rate,
blood pressure and waist circumference carries both a LOINC and a SNOMED
coding. `observation-vitalsignresult` is LOINC-only, so the SNOMED coding is
correctly reported as not a member. Verified for `364075005` (Heart rate)
and `8280-0` / `276361009` (Waist circumference). Nothing to fix locally:
the binding and the AU modelling disagree upstream.

## 1. Genuine validation findings (the data or the IG is wrong)

### 1.1 `Patient/pat-sf` carries an example identifier (29 errors, 1 defect)

```
Patient.identifier[2].system: Example URLs are not allowed in this context
  (http://www.acme.com/identifiers/patient)
```

`identifier[2]` is `{type: MB, system: http://www.acme.com/identifiers/patient}`.
That is the FHIR spec's own example system in a live fixture. With
`type = MB` the intended slice is `au-insurancemembernumber`, which it fails.

**One defect, reported 29 times** because the validator reports it against
every candidate profile in the identifier slice. Fix the fixture.

### 1.2 `AllergyIntolerance/penicillin-pat-sf` has three notes (1 error)

`SHCAllergyIntolerance` sets `note` max = 1. The resource has 3. Both the
old Aidbox validator and the HL7 validator agree on this one.

### 1.3 `Condition/ckd-pat-sf-encounter-diagnosis` missing required slice (1 error)

`SHCCondition` requires slice `Condition.category:problemListCategory`
(min = 1). The resource carries only `encounter-diagnosis`.

Worth a question back to the IG authors: requiring `problemListCategory` on
every Condition means a Condition that is legitimately only an encounter
diagnosis can never conform.

### 1.4 `NPI` is not a valid `identifier-type` (21 warnings)

Fixtures use `v2-0203#NPI` in `identifier.type` on Observation performers,
Encounter subject, and AllergyIntolerance recorder/asserter.

Verified: `$validate-code` against `identifier-type|4.0.1` returns
`result = false`. NPI exists in v2-0203 but is not in the FHIR value set,
which is a subset.

### 1.5 Resources claim profiles that do not exist (88 messages)

```
Profile reference 'http://hl7.org.au/fhir/core/StructureDefinition/au-core-observation'
  has not been checked because it could not be found
```

| Canonical | Occurrences | Status |
| --- | ---: | --- |
| `au-core-observation` | 66 | **Does not exist** in AU Core 2.0.0 |
| `au-core-lipid-result` | 6 | **Does not exist** in AU Core 2.0.0 |
| `gpccmp.csiro.au/ig/...` (7 profiles) | 12 | Different IG, shared server |
| `cvdcheck.org.au/...` | 2 | Different IG, shared server |

AU Core 2.0.0 ships 26 StructureDefinitions and there is no generic
`au-core-observation` among them; it has specific ones
(`au-core-bloodpressure`, `au-core-bodyweight`, and so on).

**This matters more than its severity suggests.** A resource declaring
`meta.profile = au-core-observation` is *not being validated against it*,
because the profile cannot be resolved. The claim is silently unchecked.

### 1.6 One inactive SNOMED concept (1 warning)

`Condition/clefttongue` uses SNOMED `204630003`. Verified `inactive = true`
on tx.dev. A retired concept; should be replaced with a current one.

### 1.7 Best practice warnings (157 warnings)

- 86 x `dom-6`: resource should have narrative
- 71 x in general, all observations should have a performer

Correct, and correctly raised at warning level. Fixable in the fixtures, or
accept them as standing warnings.

## 2. Validator and terminology server gaps (not the data's fault)

### 2.1 ICD-11 cannot be validated at all (2 messages, 1 error)

```
Unknown code 'BA41.Z&XA7RE3' in the CodeSystem
  'http://id.who.int/icd/release/11/mms' version '1.0.0'
```

The AU terminology server holds this code system with
**`content: not-present`**, meaning zero concepts. Even a plain `BA41.Z`
returns `result = false`, "could not be validated".

**This is not a data defect.** Two things follow:

1. The validator arguably has a severity bug: a `not-present` code system
   should produce a "cannot validate" warning, not an "unknown code" error.
   Worth reporting upstream.
2. Either the IG should not encourage ICD-11 in `Condition.code`, or
   tx.dev needs real ICD-11 content. As it stands any vendor sending
   ICD-11 gets an error they cannot clear.

### 2.2 MIMS and PBS code systems are unresolvable (6 warnings)

Neither validator can check `http://www.mims.com.au/codes` or
`http://pbs.gov.au/code/item`. Both are proprietary and not published as
FHIR CodeSystems. These warnings arise from `SHCMedicationStatement`
slicing `medication.coding` with `pbs` and `amt` slices, so the validator
must resolve those systems to decide slice membership.

**Correct behaviour, leave as is.** The disclosure is the point: the old
Aidbox stack returned zero messages here, which is silence, not a pass.

### 2.3 Waist circumference is not a FHIR vital sign (5 warnings)

`au-core-waistcircum` derives from the FHIR `vitalsigns` profile, whose
binding is to `observation-vitalsignresult`. Waist circumference LOINC
`8280-0` is verified **not** in that value set.

An upstream modelling tension between AU Core and FHIR core, correctly
surfaced as an extensible-binding warning. Nothing to fix locally.

### 2.4 Draft and trial-use status notices (228 info)

`Reference to draft CodeSystem http://unitsofmeasure.org` and similar.
Accurate, unavoidable, and pure volume. UCUM and several THO code systems
carry draft or trial-use status.

## 3. Test kit defects

### TK-1: Stale profile version pins (fixed in 0.0.3)

All 15 `*_reference_resolution_test.rb` files pinned target profiles to
versions the IG does not load:

| Pinned | Actually available |
| --- | --- |
| `au-core-*\|2.0.0-ballot` (120 refs) | `2.0.0` from `hl7.fhir.au.core#2.0.0` |
| `au-specimen\|5.1.0-preview` (15 refs) | `6.0.0` from `hl7.fhir.au.base#6.0.0` |

The IG declares `hl7.fhir.au.core: 2.0.0` and `hl7.fhir.au.base: 6.0.0`, so
no ballot or preview version is ever in the validation context.

**Fix applied**: version suffixes removed entirely rather than corrected to
`2.0.0` and `6.0.0`, so the tests resolve whatever the IG package supplies
and do not break again on the next package bump.

### TK-2: Reference resolution skips where it should report

`perform_reference_resolution_test` resolves a reference and then validates
the resolved resource against a target profile. If the resolved resource
*fails* profile validation, the test reports

```
Could not resolve and validate any Must Support references for subject element
```

and **skips**. Resolution and validation are conflated, so a resolvable
reference to a non-conformant resource is indistinguishable from a broken
reference, and the result is a skip rather than a finding.

Observed on `encounter_reference_resolution_test` and
`medication_statement_reference_resolution_test`, both of which fetched
`Patient/pat-sf` with HTTP 200 and then skipped. `pat-sf` genuinely fails
`au-core-patient` (finding 1.1).

Note 12 of 15 reference resolution tests pass, so this is not universally
fatal, and the exact interaction with the shared `scratch[:resolved_references]`
cache and test ordering has not been fully traced. Lives in
`inferno_suite_generator`, so it needs an upstream change.

### TK-3: Internal bookkeeping presented as findings (301 messages, 28%)

```
Registering bloodpressure-pat-sf of Observation for resource IDs registry
Registering AllergyIntolerance with 737 for teardown
```

**Over a quarter of the entire report** is the kit narrating its own
teardown registry at `info` level, in the same message list a vendor reads
to find conformance problems. These belong at debug level or nowhere.

Emitted by `inferno_suite_generator`, so the fix is upstream, or a
platform-side filter in the interim.

### TK-4: Duplicate registrations within a single test

The same resource is registered 2 to 3 times inside one test, for example
`Registering allergyintolerance-aspirin-pat-sf` three times in
`allergy_intolerance_patient_search_test`. Missing idempotency.

### TK-5: Empty resource-type sweep (15 messages)

`allergy_intolerance_create_test` emits 15 x
`No <Type> resources found. Skipping this resource type` for
ClinicalImpression, EpisodeOfCare, Appointment and others. Noise.

### TK-6: Cross-group registration

`shc_body_height_patient_search_test` registers `bloodpressure-pat-sf`.
Expected given a `patient`-only search returns all Observations, but it
makes the log confusing and inflates the count.

## 4. Test data and environment

### 4.1 QuestionnaireResponse fixtures are gone (8 tests skipped)

The whole QuestionnaireResponse group skipped. Verified against the server:
11 QuestionnaireResponses exist, **zero** for `pat-sf` or
`baby-smith-john`. Earlier the same day there were 40 for `pat-sf`.

The kit behaved correctly. This is fixture volatility on a shared, mutable
test server, and it means the largest validation surface in the suite went
unexercised in this run.

### 4.2 Other IGs' resources share the server

GP CCMP and CVD Check profiles appear on resources returned by SHC
searches. Unavoidable while both kits target one FHIR server, but it is
why some profile references cannot be resolved in an SHC-only validation
context.

## What changed in 0.0.3

1. Removed stale `|2.0.0-ballot` and `|5.1.0-preview` profile version pins
   from all 15 reference resolution tests (135 references).
2. Version bumped to 0.0.3.

## Recommended next steps, in priority order

| # | Action | Owner | Value |
| --- | --- | --- | --- |
| 1 | Fix `Patient/pat-sf identifier[2]` to a real system, or remove it | Test data | Clears 29 of 32 errors |
| 2 | Restore the QuestionnaireResponse fixtures for the test patients | Test data | Restores the largest untested surface |
| 3 | Move registry and teardown messages off `info` | `inferno_suite_generator` | Removes 28% of report volume |
| 4 | Correct or remove `au-core-observation` and `au-core-lipid-result` from `meta.profile` | Test data | Removes 72 messages, and those profile claims start being checked |
| 5 | Separate "could not resolve" from "resolved but non-conformant" | `inferno_suite_generator` | Stops findings being masked as skips |
| 6 | Fix the 3 remaining genuine defects (allergy note, condition slice, inactive SNOMED) | Test data / IG | Clears 2 of the remaining errors |
| 7 | Decide the ICD-11 position, and raise the `content: not-present` severity question upstream | IG authors / HL7 | Removes an error vendors cannot clear |
| 8 | Reconsider `SHCCondition` requiring `problemListCategory` on every Condition | IG authors | Correctness of the profile itself |

## Method

Full suite run through the Inferno API, results pulled as JSON rather than
read from the UI, so message text is exact. Messages were normalised into
354 distinct classes and each class adjudicated. Terminology claims were
verified independently with `$lookup`, `$validate-code` and `$expand`
against `tx.dev.hl7.org.au`; profile claims against the actual package
contents of `hl7.fhir.au.core#2.0.0` and `hl7.fhir.au.base#6.0.0`.
