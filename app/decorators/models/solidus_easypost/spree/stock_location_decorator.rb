# frozen_string_literal: true

module SolidusEasypost
  module Spree
    module EasyPost
      # StockLocationDecorator adds EasyPost address builder methods to the
      # stock location model.
      module StockLocationDecorator
        def easypost_address
          attributes = {
            street1: address1,
            street2: address2,
            city: city,
            zip: zipcode,
            phone: phone,
            name: name,
            company: name
          }

          attributes[:state] = state ? state.abbr : state_name
          attributes[:country] = country&.iso

          ::EasyPost::Address.create attributes
        end

        # @return [Hash] an EasyPost compatible address hash
        # rubocop:disable MethodLength
        def easypost_hash
          {
            street1: address1,
            street2: address2,
            city: city,
            state: state&.abbr || state_name,
            zip: zipcode,
            country: country&.iso,
            phone: phone,
            name: full_name,
            company: name
          }
        end
        # rubocop:enable MethodLength

        ::Spree::StockLocation.prepend self
      end
    end
  end
end
