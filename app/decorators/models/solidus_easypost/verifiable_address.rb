# frozen_string_literal: true

module SolidusEasypost
  # VerifiableAddress provides a central service for checking EasyPost's
  # acceptance of an address as early in the Solidus workflow as possible.
  class VerifiableAddress
    include ActiveModel::Model
    attr_accessor :street1
    attr_accessor :street2
    attr_accessor :city
    attr_accessor :name
    attr_accessor :company
    attr_accessor :state
    attr_accessor :country
    attr_accessor :zip
    attr_accessor :phone

    validates :street1, presence: true

    validates :city, presence: true
    validates :state, presence: true

    validates :zip, presence: true

    validate :easypost_approved

    def memo_hash
      join %i[street1 street2 city zip phone]
    end

    # Coerce model params to easypost format
    # {:name=>"John Doe", :company=>"Company",
    #   :street1=>"A Different Road", :street2=>"Northwest",
    #   :city=>"Manville", :state=>"NJ", :zip=>"08835",
    #   :country=>"US", :phone=>"555-555-0199"}
    def easypost_params
      attrs = %i[name company street1 street2 city state zip country phone]
      attrs.map { |attr_name| [attr_name, send(attr_name)] }
           .to_h
           .merge(verification_params)
    end

    def easypost_approved
      to_easypost.verifications.each do |_key, value|
        next if value.try(:success)

        handle_verification_failure! value

        msg = ["EasyPost address verification failure response: [#{value}].",
               "What we sent: [#{easypost_params}]"].join ' '
        errors.add :base, msg
      end
    end

    def to_easypost
      @to_easypost ||= begin
                         ::EasyPost::Address.create easypost_params
                       rescue ::EasyPost::Error => e
                         handle_verification_failure! e.message
                         raise
                       end
    end

    def handle_verification_failure!(response)
      msg = ['EasyPost address verification failure response:',
             " [#{response}]. What we sent: [#{easypost_params}]"].join ' '
      errors.add :base, msg
    end

    def self.from_stock_location(stock_location)
      new stock_location.easypost_hash
    end

    def self.from_solidus_address(addr)
      new addr.easypost_hash
    end

    private

    def verification_params
      return {} unless ::Spree::Easypost::Config.address_verification_enabled

      if ::Spree::Easypost::Config.verify_strict_enabled
        { verify_strict: ['delivery'] }
      else
        { verify: ['delivery'] }
      end
    end
  end
end
