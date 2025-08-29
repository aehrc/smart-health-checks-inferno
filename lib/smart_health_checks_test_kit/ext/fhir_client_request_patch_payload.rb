# frozen_string_literal: true

begin
  require 'crud'
rescue LoadError
end

module FHIR
  class Client
    def request_patch_payload(patchset, format)
      case format
      when "#{FHIR::Formats::PatchFormat::FHIRPATH_PATCH};charset=utf-8"
        patchset = FHIR.from_contents(patchset)
        patchset.to_json if patchset.is_a?(FHIR::Parameters)
      when FHIR::Formats::PatchFormat::PATCH_JSON
        patchset.each do |patch|
          patch[:path] = patch[:path].slice(patch[:path].index('/')..-1)
        end
        patchset.to_json
      when FHIR::Formats::PatchFormat::PATCH_XML
        builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          patchset.each do |patch|
            xml.diff do
              # TODO: support other kinds besides just replace
              xml.replace(patch[:value], sel: "#{patch[:path]}/@value") if patch[:op] == 'replace'
            end
          end
        end
        builder.to_xml
      else
        # type code here
      end
    end
    private :request_patch_payload
  end
end
