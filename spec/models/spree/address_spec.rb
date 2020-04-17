# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::Address, :vcr do
  let(:address) { create :address }
  subject { address.easypost_address }

  describe '#easypost_address' do

    it 'is an EasyPost::Address object' do
      expect(subject).to be_a(EasyPost::Address)
    end

    it 'has the correct attributes' do
      # combination of original address factory from easy post
      # and the spree_modification factories
      expect(subject).to have_attributes(
        name: 'John Doe',
        company: 'Company',
        street1: '215 N 7th Ave',
        street2: 'Northwest',
        city: 'Manville',
        state: 'NJ',
        zip: '08835',
        country: 'US',
        phone: '5555550199'
      )
    end

    context 'address_verification_enabled' do
      it 'doesnt verify the address inputted' do
        Spree::Easypost::Config.address_verification_enabled = false

        expect(subject['verifications']['delivery']).to be_nil
      end

      it 'verifies the address inputted' do
        Spree::Easypost::Config.address_verification_enabled = true

        expect(subject['verifications']['delivery']['success']).to be_truthy
      end

      it 'error' do
        Spree::Easypost::Config.address_verification_enabled = true

        address1 = create(:address, zipcode: "324324234324", address1: "34 fdgdfgfd")

        expect { address1.easypost_address }.to raise_error
      end
    end

    context 'verify_strict_enabled' do
      it 'strictly verifies the address inputted' do
        Spree::Easypost::Config.address_verification_enabled = true
        Spree::Easypost::Config.verify_strict_enabled = true

        address1 = create(:address, zipcode: "324324234324", address1: "34 fdgdfgfd")

        expect { address1.easypost_address }.to raise_error
      end
    end


  end
end
