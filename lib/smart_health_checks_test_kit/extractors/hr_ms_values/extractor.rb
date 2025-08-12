# frozen_string_literal: true

require 'inferno_suite_generator/extractors/must_support_metadata_extractor'

module InfernoSuiteGenerator
  class Generator
    class HRMSValuesExtractor < MustSupportMetadataExtractor
      ELEMENT_ID = 'Observation.category:vitalSignsCategory'
      SLICE_NAME = 'vitalSignsCategory'
      DEFAULT_VALUES = [
        {
          path: 'code',
          value: 'vital-signs'
        },
        {
          path: 'system',
          value: 'http://terminology.hl7.org/CodeSystem/observation-category'
        }
      ].freeze

      def value_slices
        must_support_value_slice_elements.map do |current_element|
          default_element_data(current_element).tap do |metadata|
            metadata[:discriminator][:values] = handle_custom_values(current_element)
          end
        end
      end

      private

      def handle_custom_values(element)
        if element.id == ELEMENT_ID && element.sliceName == SLICE_NAME
          DEFAULT_VALUES
        else
          discriminator_values(element)
        end
      end

      def default_element_data(element)
        {
          slice_id: element.id,
          slice_name: element.sliceName,
          path: element.path.gsub("#{resource}.", ''),
          discriminator: {
            type: 'value'
          }
        }
      end

      def discriminator_values(current_element)
        discriminators(sliced_element(current_element)).map do |discriminator|
          fixed_element = profile_elements.find do |element|
            element.id.starts_with?(current_element.id) &&
              element.path == "#{current_element.path}.#{discriminator.path}"
          end

          next unless fixed_element

          {
            path: discriminator.path,
            value: fixed_element.fixedUri || fixed_element.fixedCode
          }
        end
      end
    end
  end
end
