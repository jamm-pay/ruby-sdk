# frozen_string_literal: true

require 'openssl'
require 'rest-client'
require 'json'
require 'base64'
require 'jamm/errors'

module Jamm
  module Webhook
    # Parse command is for parsing the received webhook message.
    # It does not call anything remotely, instead returns the suitable object.
    def self.parse(json)
      out = Jamm::OpenAPI::MerchantWebhookMessage.new(json)

      case json[:event_type]
      when Jamm::OpenAPI::EventType::CHARGE_CREATED
        out.content = Jamm::OpenAPI::ChargeMessage.new(json[:content])
        return out

      when Jamm::OpenAPI::EventType::CHARGE_UPDATED
        out.content = Jamm::OpenAPI::ChargeMessage.new(json[:content])
        return out

      when Jamm::OpenAPI::EventType::CHARGE_CANCEL
        out.content = Jamm::OpenAPI::ChargeMessage.new(json[:content])
        return out

      when Jamm::OpenAPI::EventType::CHARGE_SUCCESS
        out.content = Jamm::OpenAPI::ChargeMessage.new(json[:content])
        return out

      when Jamm::OpenAPI::EventType::CHARGE_FAIL
        out.content = Jamm::OpenAPI::ChargeMessage.new(json[:content])
        return out

      when Jamm::OpenAPI::EventType::CONTRACT_ACTIVATED
        out.content = Jamm::OpenAPI::ContractMessage.new(json[:content])
        return out
      end

      raise 'Unknown event type'
    end

    # Verify message
    def self.verify(data:, signature:)
      raise ArgumentError, 'data cannot be nil' if data.nil?
      raise ArgumentError, 'signature cannot be nil' if signature.nil?

      # Convert the JSON to a string
      json = JSON.dump(data)

      digest = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), Jamm.client_secret, json)
      given = "sha256=#{digest}"

      return if secure_compare(given, signature)

      raise Jamm::InvalidSignatureError, 'Digests do not match'
    end

    # Securely compare two strings of equal length.
    # This method is a port of ActiveSupport::SecurityUtils.secure_compare
    # which works on non-Rails platforms.
    def self.secure_compare(a, b)
      return false unless a.bytesize == b.bytesize

      # Unpack strings into arrays of bytes
      a_bytes = a.unpack('C*')
      b_bytes = b.unpack('C*')
      result = 0

      # XOR each byte and accumulate the result
      a_bytes.zip(b_bytes) { |x, y| result |= x ^ y }
      result.zero?
    end
  end
end
