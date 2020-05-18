# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

describe Spree::Stock::Package, :vcr do
  let(:package) { create(:shipment).to_package }

  describe '#easypost_parcel' do
    subject { package.easypost_parcel }

    it 'is an EasyPost::Parcel object' do
      expect(subject).to be_a(EasyPost::Parcel)
    end

    it 'has the correct attributes' do
      expect(subject).to have_attributes(
        object: 'Parcel',
        weight: 10.0
      )
    end
  end

  describe '#easypost_shipment' do
    subject { package.easypost_shipment }

    it 'is an EasyPost::Shipment object' do
      expect(subject).to be_a(EasyPost::Shipment)
    end

    it 'calls the api' do
      expect(EasyPost::Shipment).to receive(:create).with(anything)
      subject
    end
  end

  describe '#easypost_address' do
    let(:package) { create(:shipment, :invalid_address).to_package }
    let(:order) { double 'order' }
    let(:ship_address ) { double 'ship_address' }
    let(:easy_address) { double 'easy address' }

    let(:invalid_address_error) { OpenStruct.new message: "it's a bad address!" }
    let(:delivery_verification) { OpenStruct.new success: false, errors: [invalid_address_error] }
    let(:verifications) { OpenStruct.new delivery: delivery_verification }

    let(:model_errors) { ActiveModel::Errors.new(order) }

    before do
      allow(package).to receive(:order).and_return(order)
      allow(order).to receive(:ship_address).and_return(ship_address)
      allow(ship_address).to receive(:easypost_address).and_return(easy_address)
      allow(easy_address).to receive(:verifications).and_return(verifications)
      allow(order).to receive(:errors).and_return(model_errors)
      ::Spree::Easypost::Config.address_verification_enabled = true
    end

    context 'unverifiable address' do
      it 'mentions easypost in its order errors object' do
        package.easypost_address

        expect(order.errors).not_to be_empty

        errors = order.errors
        expect(errors).to be_a ActiveModel::Errors

        err_msg = errors[:address].join

        expect(err_msg).to include package.error_label
        expect(err_msg).to include invalid_address_error.message
      end
    end

  end
end
