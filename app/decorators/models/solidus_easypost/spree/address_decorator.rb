# frozen_string_literal: true

module SolidusEasypost
  module Spree
    module EasyPost
      # AddressDecorator adds EasyPost object builders to Spree Address.
      module AddressDecorator
        def easypost_address
          VerifiableAddress
            .from_solidus_address(self)
            .to_easypost
        end

        # @return [Hash] an EasyPost compatible address hash
        # rubocop:disable Metrics/MethodLength
        def easypost_hash
          {
            name: full_name,
            street1: address1,
            street2: address2,
            city: city,
            state: state_text,
            zip: zipcode,
            country: country.try(:iso),
            phone: phone,
            company: company
          }
        end
        # rubocop:enable Metrics/MethodLength

        ::Spree::Address.prepend self
      end
    end
  end
end
