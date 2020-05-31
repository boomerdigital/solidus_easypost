# frozen_string_literal: true

module SolidusEasypost
  module Spree
    module Stock
      # EstimatorDecorator adds easypost shipping rate calculation elements to
      # Spree::Stock::Estimator.
      module EstimatorDecorator
        def shipping_rates(package, frontend_only = true)
          build_easypost_shipping_rates package, frontend_only
        rescue ::EasyPost::Error => e
          msg = "[#{e.class}] EasyPost ship rate builder error: #{e.message}"
          Rails.logger.error msg
          super
        end

        private

        def build_easypost_shipping_rates(package, frontend_only = true)
          return super unless package_easypost_eligible?(package)

          easypost_rates = package
                           .easypost_shipment
                           .rates
                           .sort_by { |r| r.rate.to_i }

          ship_rates = initialize_ship_rates(frontend_only, package)

          return [] unless easypost_rates.any?

          capture_rates!(easypost_rates, package.shipping_methods, ship_rates)

          # Sets cheapest rate to be selected by default
          ship_rates&.min_by(&:cost)&.selected = true

          ship_rates
        end

        def initialize_ship_rates(frontend_only, package)
          rates = calculate_shipping_rates(package)
          if frontend_only
            rates.select! { |r| r.shipping_method.available_to_users? }
            rates.reject! { |r| r.shipping_method.is_easypost }
          end
          rates
        end

        def spree_rate_for(rate, shipping_method)
          ::Spree::ShippingRate.new(
            name: "#{rate.carrier} #{rate.service}",
            cost: rate.rate,
            easy_post_shipment_id: rate.shipment_id,
            easy_post_rate_id: rate.id,
            shipping_method: shipping_method
          )
        end

        def capture_rates!(easypost_rates, ship_methods, ship_rates)
          easypost_rates.each do |rate|
            shipping_method = find_or_create_shipping_method(rate)
            next unless shipping_method.available_to_users?
            next unless ship_methods.include?(shipping_method)

            ship_rates << spree_rate_for(rate, shipping_method)
          end
        end

        # Cartons require shipping methods to be present, This will lookup a
        # Shipping method based on the admin(internal)_name.
        # This is not user facing and should not be changed in the admin.
        def find_or_create_shipping_method(rate)
          method_name = "#{rate.carrier} #{rate.service}"
          ::Spree::ShippingMethod
            .find_or_create_by(admin_name: method_name) do |sm|
            sm.name = method_name
            sm.available_to_users = false
            sm.is_easypost = true
            sm.code = rate.service
            sm.calculator = ::Spree::Calculator::Shipping::FlatRate.create
            sm.shipping_categories = [::Spree::ShippingCategory.first]
          end
        end

        def package_easypost_eligible?(package)
          ::Spree::Easypost::Config.api_enabled &&
            !package.stock_location.is_digital?
        end

        ::Spree::Stock::Estimator.prepend self
      end
    end
  end
end
