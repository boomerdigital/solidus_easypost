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
           .merge(verify: verification_params)
    end

    def easypost_approved
      verifications.each do |_key, value|
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
                       end
    end

    def handle_verification_failure!(response)
      msg = ['EasyPost address verification failure response:',
             " [#{response}]. What we sent: [#{easypost_params}]"].join ' '
      errors.add :base, msg
    end

    def verifications
      verification_params.map do |field|
        [field, to_easypost.verifications.try(field)]
      end
    end

    def self.from_stock_location(stock_location)
      new stock_location.easypost_hash
    end

    def self.from_ship_address(addr)
      new addr.easypost_hash
    end

    private

    def verification_params
      %w[delivery zip4]
    end

    def should_verify?
      #::Spree::Easypost::Config.address_verification_enabled
      true
    end
  end
end
