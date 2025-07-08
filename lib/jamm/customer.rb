# frozen_string_literal: true

require 'rest-client'
require 'json'
require 'base64'
require 'jamm/errors'
require 'jamm/api/models/v1_create_customer_request'

module Jamm
  module Customer
    # Embed enum statuses into Customer module for easier access
    # and not to leak OpenAPI namespace into merchant codebase.
    #
    # - Before: Jamm::OpenAPI::KycStatus
    # - After:  Jamm::Customer::KycStatus
    KycStatus = Jamm::OpenAPI::KycStatus
    PaymentAuthorizationStatus = Jamm::OpenAPI::PaymentAuthorizationStatus

    def self.create(buyer:)
      r = Jamm::OpenAPI::CustomerApi.new(Jamm::Client.handler).create(
        buyer: buyer
      )

      r.customer
    rescue Jamm::OpenAPI::ApiError => e
      raise Jamm::ApiError.from_error(e)
    end

    def self.get(id_or_email)
      r = Jamm::OpenAPI::CustomerApi.new(Jamm::Client.handler).get(id_or_email)

      if r.customer.activated.nil?
        # Activated flag requires explicit binding on false, since RPC/OpenAPI does
        # not return false value.
        r.customer.activated = false
      end

      r.customer
    rescue Jamm::OpenAPI::ApiError => e
      raise Jamm::ApiError.from_error(e)
    end

    def self.get_contract(id)
      Jamm::OpenAPI::CustomerApi.new(Jamm::Client.handler).get_contract(id)
    rescue Jamm::OpenAPI::ApiError => e
      return nil if [404].include?(e.code)

      raise Jamm::ApiError.from_error(e)
    end

    def self.update(id, params)
      r = Jamm::OpenAPI::CustomerApi.new(Jamm::Client.handler).update(id, params)

      r.customer
    rescue Jamm::OpenAPI::ApiError => e
      raise Jamm::ApiError.from_error(e)
    end

    def self.delete(id)
      Jamm::OpenAPI::CustomerApi.new(Jamm::Client.handler).delete(id)
    rescue Jamm::OpenAPI::ApiError => e
      raise Jamm::ApiError.from_error(e)
    end
  end
end
