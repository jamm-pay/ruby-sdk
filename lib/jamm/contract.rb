# frozen_string_literal: true

require 'rest-client'
require 'json'
require 'base64'
require 'jamm/errors'

module Jamm
  module Contract
    def self.create_with_charge(buyer:, charge:, redirect:)
      request = Jamm::OpenAPI::CreateContractWithChargeRequest.new(
        buyer: buyer,
        charge: charge,
        redirect: redirect
      )

      Jamm::OpenAPI::PaymentApi.new(Jamm::Client.handler).create_contract_with_charge(request)
    rescue Jamm::OpenAPI::ApiError => e
      raise Jamm::ApiError.from_error(e)
    end

    def self.create_without_charge(buyer:, redirect:)
      request = Jamm::OpenAPI::CreateContractWithoutChargeRequest.new(
        buyer: buyer,
        redirect: redirect
      )

      Jamm::OpenAPI::PaymentApi.new(Jamm::Client.handler).create_contract_without_charge(request)
    rescue Jamm::OpenAPI::ApiError => e
      raise Jamm::ApiError.from_error(e)
    end

    def self.get(customer_id)
      Jamm::OpenAPI::CustomerApi.new(Jamm::Client.handler).get_contract(customer_id)
    rescue Jamm::OpenAPI::ApiError => e
      [404].include?(e.code) ? nil : Jamm::ApiError.from_error(e)
    end
  end
end
