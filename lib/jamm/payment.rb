# frozen_string_literal: true

require 'rest-client'
require 'json'
require 'base64'
require 'jamm/errors'

module Jamm
  module Payment
    def self.on_session(charge:, redirect:, customer: nil, buyer: nil)
      request = if customer.nil?
                  Jamm::OpenAPI::OnSessionPaymentRequest.new(
                    buyer: buyer,
                    charge: charge,
                    redirect: redirect
                  )
                else
                  Jamm::OpenAPI::OnSessionPaymentRequest.new(
                    customer: customer,
                    charge: charge,
                    redirect: redirect
                  )
                end

      Jamm::OpenAPI::PaymentApi.new(Jamm::Client.handler).on_session_payment(request)
    rescue Jamm::OpenAPI::ApiError => e
      raise Jamm::ApiError.from_error(e)
    end

    def self.off_session(customer:, charge:)
      request = Jamm::OpenAPI::OffSessionPaymentRequest.new(
        customer: customer,
        charge: charge
      )

      Jamm::OpenAPI::PaymentApi.new(Jamm::Client.handler).off_session_payment(request)
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
