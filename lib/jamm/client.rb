# frozen_string_literal: true

module Jamm
  module Client
    def self.handler(merchant: nil)
      base = Jamm::OpenAPI::ApiClient.new

      # Configure
      base.config.host = Jamm.openapi.config.host
      base.config.scheme = Jamm.openapi.config.scheme
      base.default_headers['Authorization'] = "Bearer #{Jamm::OAuth.token}"

      # Platform feature, optionally set merchant id to call Jamm API
      # on behalf of the merchant.
      if merchant
        unless defined?(Jamm::Mode) && Jamm.respond_to?(:mode) && Jamm.mode == Jamm::Mode::PLATFORM
          raise ArgumentError, 'merchant can only be set when Jamm.mode is Jamm::Mode::PLATFORM'
        end

        # Merchant ID format validation to match backend expectations (e.g. "mer-*").
        unless merchant.is_a?(String) && merchant.match?(/\Amer-[0-9A-Za-z_-]+\z/)
          raise ArgumentError, 'invalid merchant id format (expected something like "mer-*")'
        end

        base.default_headers['Jamm-Merchant'] = merchant
      end
      base
    end
  end
end
