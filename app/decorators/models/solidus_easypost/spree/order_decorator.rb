# frozen_string_literal: true

module SolidusEasypost
  module Spree
    module OrderDecorator
      def self.prepended(base)
        base.state_machine.before_transition from: :address,
          do: :validate_ship_address,
          if: :address_verification_enabled?
      end

      def validate_ship_address
        easypost_address_response = ship_address.easypost_address
        address_verification_obj = address_response.verifications.delivery

          if address_verification_obj.success
            return true
          else
            messages = address_verification_obj.errors.map { |e| e.message }.join(". ")

            errors.add(:base, messages)
          end
        false
      end

      def address_verification_enabled?
        ship_address.verification_enabled?
      end

      ::Spree::Order.prepend self
    end
  end
end
