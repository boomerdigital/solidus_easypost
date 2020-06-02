# frozen_string_literal: true

EasyPost.api_key = 'EZTKa6a3653e4e3f4b2883013f4c20e1f28b6camRFWNI0aRqQQqDnQKkg'
Spree::Easypost::Config.api_enabled = true
Spree::Easypost::Config.address_verification_enabled = false
Spree::Easypost::Config.verify_strict_enabled = false

def fail_easypost_shipment_create!
  allow(::EasyPost::Shipment).to(
    receive(:create)
        .and_raise(EasyPost::Error)
  )
end

def enable_address_verification!
  allow(::Spree::Easypost::Config).to(
    receive(:address_verification_enabled)
        .and_return(true)
  )
end
