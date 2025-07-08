# frozen_string_literal: true

require 'rest-client'
require 'json'
require 'base64'
require 'jamm/errors'

module Jamm
  module Charge
    def self.create_with_redirect(customer:, charge:, redirect:)
      request = Jamm::OpenAPI::AddChargeRequest.new(
        customer: customer,
        charge: charge,
        redirect: redirect
      )

      Jamm::OpenAPI::PaymentApi.new(Jamm::Client.handler).add_charge(request)
    rescue Jamm::OpenAPI::ApiError => e
      raise Jamm::ApiError.from_error(e)
    end

    def self.create_without_redirect(customer:, charge:)
      request = Jamm::OpenAPI::WithdrawRequest.new(
        customer: customer,
        charge: charge
      )

      Jamm::OpenAPI::PaymentApi.new(Jamm::Client.handler).withdraw(request)
    rescue Jamm::OpenAPI::ApiError => e
      raise Jamm::ApiError.from_error(e)
    end

    def self.get(charge_id)
      Jamm::OpenAPI::PaymentApi.new(Jamm::Client.handler).get_charge(charge_id)
    rescue Jamm::OpenAPI::ApiError => e
      return nil if e.code == 404

      raise Jamm::ApiError.from_error(e)
    end

    def self.list(customer:, pagination: nil)
      Jamm::OpenAPI::PaymentApi.new(Jamm::Client.handler).get_charges(customer, pagination.nil? ? {} : pagination)
    rescue Jamm::OpenAPI::ApiError => e
      if [404].include?(e.code)
        nil
      else
        {
          charges: []
        }
      end
    end
  end
end
