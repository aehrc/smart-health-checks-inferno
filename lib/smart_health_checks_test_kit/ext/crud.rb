# frozen_string_literal: true

module FHIR
  module Sections
    module Crud
      def is_fhirpath_patch?(patchset, format)
        patchset.is_a?(String) && format == FHIR::Formats::PatchFormat::FHIRPATH_PATCH
      end

      def partial_update(klass, id, patchset, options = {}, format = nil)
        headers = {}
        headers[:accept] =  format.to_s if format
        format ||= @default_format
        options = { resource: klass, id: id, format: format }.merge options
        if is_fhirpath_patch?(patchset, format)
          options[:format] = FHIR::Formats::PatchFormat::FHIRPATH_PATCH
          headers[:content_type] = FHIR::Formats::PatchFormat::FHIRPATH_PATCH.to_s
        elsif [FHIR::Formats::ResourceFormat::RESOURCE_XML, FHIR::Formats::ResourceFormat::RESOURCE_XML_DSTU2].include?(format)
          options[:format] = FHIR::Formats::PatchFormat::PATCH_XML
          headers[:content_type] = FHIR::Formats::PatchFormat::PATCH_XML.to_s
        elsif [FHIR::Formats::ResourceFormat::RESOURCE_JSON, FHIR::Formats::ResourceFormat::RESOURCE_JSON_DSTU2].include?(format)
          options[:format] = FHIR::Formats::PatchFormat::PATCH_JSON
          headers[:content_type] = FHIR::Formats::PatchFormat::PATCH_JSON.to_s
        end
        headers[:prefer] = @return_preference if @use_return_preference
        reply = patch resource_url(options), patchset, fhir_headers(headers)
        reply.resource = parse_reply(klass, format, reply)
        reply.resource_class = klass
        reply
      end
    end
  end
end
