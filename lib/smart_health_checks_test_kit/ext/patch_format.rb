# frozen_string_literal: true

module FHIR
  module Formats
    class PatchFormat
      PATCH_XML = 'application/xml-patch+xml'
      PATCH_JSON = 'application/json-patch+json'
      FHIRPATH_PATCH = 'application/fhir+json'
    end
  end
end
