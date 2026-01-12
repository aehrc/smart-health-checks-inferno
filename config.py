import os
import json
"""
Configuration file for AEHRC Smart Health Checks Inferno Aidbox project.

This module will auto-generate the config file using 'make prepare-config-file' command.
It reads environment variables and creates the necessary configuration file 'config.py'
for the application to run properly.

Author: Janardhan Vignarajan CSIRO AEHRC (Australian eHealth Research Centre)

"""

# Configuration will be populated by makefile prepare-config-file command
# Environment variables are read and injected into this file at build time


from pathlib import Path
import os

def load_env_file(path=".env"):
    p = Path(path)
    if not p.exists():
        return
    for line in p.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        k = k.strip()
        v = v.strip().strip('"').strip("'")
        os.environ.setdefault(k, v)

load_env_file(".env")


IG_VERSION_NUMBER = os.getenv("IG_VERSION_NUMBER", "0.4.0") # Read it from the .env file, defaults to 0.4.0 
IG_VERSION_STRING = os.getenv("IG_VERSION_STRING", "v040")  # Read it from the .env file, defaults to v040 


dict_to_create = {
    "ig": {
        "id": "csiro.fhir.au.smartforms",
        "version": f"{IG_VERSION_NUMBER}",
        "name": "Smart Health Checks Implementation Guide",
        "link": f"https://smartforms.csiro.au/ig/{IG_VERSION_NUMBER}/index.html",
        "cs_profile_url": "https://smartforms.csiro.au/ig/CapabilityStatement/SHCHostFHIRServerCapabilityStatement",
        "cs_version_specific_url": "https://smartforms.csiro.au/ig/CapabilityStatement/SHCHostFHIRServerCapabilityStatement",
        "package_archive_path": f"lib/smart_health_checks_test_kit/igs/{IG_VERSION_NUMBER}.tgz",
    },
    "suite": {
        "title": "Smart Health Checks",
        "extra_json_paths": [
            "search-params.json",
            "example-resources.json",
            "patch-bundle.json",
        ],
        "tx_server_url": "https://tx.dev.hl7.org.au/fhir",
        "rewrite_igs": f"/home/igs/{IG_VERSION_NUMBER}.tgz",
        "extra_imports": [
            {
                "import_type": "relative",
                "import_path": "../../ext/fhir_client_request_patch_payload",
            },
            {"import_type": "relative", "import_path": "../../ext/crud"},
            {"import_type": "relative", "import_path": "../../ext/patch_format"},
        ],
        "outer_groups": [
            {
                "import_type": "relative",
                "import_path": "../../outer_groups/teardown",
                "group_position": "after",
                "group_id": f"smart_health_checks_{IG_VERSION_STRING}_teardown",
            }
        ],
        "links": [
            {
                "label": "Report Issue",
                "url": "https://github.com/aehrc/smart-health-checks-inferno/issues",
            },
            {
                "label": "Source Code",
                "url": "https://github.com/aehrc/smart-health-checks-inferno",
            },
            {
                "label": "Implementation Guide",
                "url": "https://build.fhir.org/ig/aehrc/smart-forms-ig/index.html",
            },
        ],
    },
    "constants": {
        "default_fhir_server": "https://proxy.smartforms.io/fhir",
        "read_ids.patient": "pat-sf",
        "read_ids.encounter": "health-check-pat-sf",
        "read_ids.practitioner": "primary-peter",
    },
    "configs": {
        "generic": {
            "expectation": ["SHALL", "SHOULD", "MAY"],
            "search_params_to_ignore": ["_count", "_sort", "_include"],
            "rewrite_profile_url": {
                "http://hl7.org.au/fhir/core/StructureDefinition/au-core-patient": "http://hl7.org.au/fhir/core/StructureDefinition/au-core-patient|2.0.0-ballot",
                "http://hl7.org.au/fhir/core/StructureDefinition/au-core-encounter": "http://hl7.org.au/fhir/core/StructureDefinition/au-core-encounter|2.0.0-ballot",
                "http://hl7.org.au/fhir/core/StructureDefinition/au-core-location": "http://hl7.org.au/fhir/core/StructureDefinition/au-core-location|2.0.0-ballot",
                "http://hl7.org.au/fhir/core/StructureDefinition/au-core-practitioner": "http://hl7.org.au/fhir/core/StructureDefinition/au-core-practitioner|2.0.0-ballot",
                "http://hl7.org.au/fhir/core/StructureDefinition/au-core-practitionerrole": "http://hl7.org.au/fhir/core/StructureDefinition/au-core-practitionerrole|2.0.0-ballot",
                "http://hl7.org.au/fhir/core/StructureDefinition/au-core-organization": "http://hl7.org.au/fhir/core/StructureDefinition/au-core-organization|2.0.0-ballot",
                "http://hl7.org.au/fhir/core/StructureDefinition/au-core-relatedperson": "http://hl7.org.au/fhir/core/StructureDefinition/au-core-relatedperson|2.0.0-ballot",
                "http://hl7.org.au/fhir/core/StructureDefinition/au-core-diagnosticresult-path": "http://hl7.org.au/fhir/core/StructureDefinition/au-core-diagnosticresult-path|2.0.0-ballot",
                "http://hl7.org.au/fhir/StructureDefinition/au-specimen": "http://hl7.org.au/fhir/StructureDefinition/au-specimen|5.1.0-preview",
            },
        },
        "profiles": {
            "https://smartforms.csiro.au/ig/StructureDefinition/SHCBloodPressure": {
                "filter_set": [
                    [
                        {
                            "expression": "$.code.coding[?(@.system == 'http://loinc.org')].code",
                            "value": "85354-9",
                        }
                    ],
                    [
                        {
                            "expression": "$.code.coding[?(@.system == 'http://snomed.info/sct')].code",
                            "value": "75367002",
                        }
                    ],
                ]
            },
            "https://smartforms.csiro.au/ig/StructureDefinition/SHCBodyHeight": {
                "filter_set": [
                    [
                        {
                            "expression": "$.code.coding[?(@.system == 'http://loinc.org')].code",
                            "value": "8302-2",
                        }
                    ],
                    [
                        {
                            "expression": "$.code.coding[?(@.system == 'http://snomed.info/sct')].code",
                            "value": "50373000",
                        }
                    ],
                ]
            },
            "https://smartforms.csiro.au/ig/StructureDefinition/SHCBodyWeight": {
                "filter_set": [
                    [
                        {
                            "expression": "$.code.coding[?(@.system == 'http://loinc.org')].code",
                            "value": "29463-7",
                        }
                    ],
                    [
                        {
                            "expression": "$.code.coding[?(@.system == 'http://snomed.info/sct')].code",
                            "value": "27113001",
                        }
                    ],
                ]
            },
            "https://smartforms.csiro.au/ig/StructureDefinition/SHCHeartRate": {
                "filter_set": [
                    [
                        {
                            "expression": "$.code.coding[?(@.system == 'http://loinc.org')].code",
                            "value": "8867-4",
                        }
                    ],
                    [
                        {
                            "expression": "$.code.coding[?(@.system == 'http://snomed.info/sct')].code",
                            "value": "364075005",
                        }
                    ],
                ]
            },
            "https://smartforms.csiro.au/ig/StructureDefinition/SHCSmokingStatus": {
                "filter_set": [
                    [
                        {
                            "expression": "$.code.coding[?(@.system == 'http://loinc.org')].code",
                            "value": "72166-2",
                        }
                    ],
                    [
                        {
                            "expression": "$.code.coding[?(@.system == 'http://snomed.info/sct')].code",
                            "value": "1747861000168109",
                        }
                    ],
                ]
            },
            "https://smartforms.csiro.au/ig/StructureDefinition/SHCWaistCircumference": {
                "filter_set": [
                    [
                        {
                            "expression": "$.code.coding[?(@.system == 'http://loinc.org')].code",
                            "value": "8280-0",
                        }
                    ],
                    [
                        {
                            "expression": "$.code.coding[?(@.system == 'http://snomed.info/sct')].code",
                            "value": "276361009",
                        }
                    ],
                ]
            },
            "https://smartforms.csiro.au/ig/StructureDefinition/SHCHeadCircumference": {
                "filter_set": [
                    [
                        {
                            "expression": "$.code.coding[?(@.system == 'http://loinc.org')].code",
                            "value": "9843-4",
                        }
                    ],
                    [
                        {
                            "expression": "$.code.coding[?(@.system == 'http://snomed.info/sct')].code",
                            "value": "363812007",
                        }
                    ],
                ]
            },
            "https://smartforms.csiro.au/ig/StructureDefinition/SHCPatient": {
                "first_class_profile": "read"
            },
            "https://smartforms.csiro.au/ig/StructureDefinition/SHCPractitioner": {
                "first_class_profile": "read"
            },
            "https://smartforms.csiro.au/ig/StructureDefinition/SHCEncounter": {
                "first_class_profile": "read"
            },
            "https://smartforms.csiro.au/ig/StructureDefinition/SHCHeartRhythm": {
                "filter_set": [
                    [
                        {
                            "expression": "$.code.coding[?(@.system == 'http://loinc.org')].code",
                            "value": "8884-9",
                        }
                    ],
                    [
                        {
                            "expression": "$.code.coding[?(@.system == 'http://snomed.info/sct')].code",
                            "value": "364074009",
                        }
                    ],
                ],
                "register_extractors": [
                    {
                        "path_to_extractor": "lib/smart_health_checks_test_kit/extractors/hr_ms_values/extractor.rb",
                        "extractor_class": "InfernoSuiteGenerator::Generator::HRMSValuesExtractor",
                        "extractor_type": "must_support",
                    }
                ],
            },
            "https://smartforms.csiro.au/ig/StructureDefinition/SHCPathologyResult": {
                "search_param": {"clinical-code": {"default_values": ["32309-7"]}}
            },
        },
        "resources": {
            "Medication": {"skip": True},
            "DiagnosticReport": {"skip": True},
            "Bundle": {"skip": True},
            "Parameters": {"skip": True},
        },
    },
}


with open('config.json', 'w') as f:
    f.write(json.dumps(dict_to_create, indent=2))