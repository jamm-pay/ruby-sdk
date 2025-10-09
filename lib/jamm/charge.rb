# frozen_string_literal: true

require 'rest-client'
require 'json'
require 'base64'
require 'jamm/errors'

module Jamm
  module Charge
    # DEPRECATED, use Jamm::Payment.on_session
    def self.create_with_redirect(customer:, charge:, redirect: nil)
      Jamm::Deprecation.warn('Jamm::Charge.create_with_redirect')

      request = Jamm::OpenAPI::AddChargeRequest.new(
        customer: customer,
        charge: charge,
        redirect: redirect
      )

      Jamm::OpenAPI::PaymentApi.new(Jamm::Client.handler).add_charge(request)
    rescue Jamm::OpenAPI::ApiError => e
      raise Jamm::ApiError.from_error(e)
    end

    # DEPRECATED, use Jamm::Payment.off_session
    def self.create_without_redirect(customer:, charge:)
      Jamm::Deprecation.warn('Jamm::Charge.create_without_redirect')

      request = Jamm::OpenAPI::WithdrawRequest.new(
        customer: customer,
        charge: charge
      )

      Jamm::OpenAPI::PaymentApi.new(Jamm::Client.handler).withdraw(request)
    rescue Jamm::OpenAPI::ApiError => e
      raise Jamm::ApiError.from_error(e)
    end

    # DEPRECATED, use Jamm::Payment.get
    def self.get(charge_id)
      Jamm::Deprecation.warn('Jamm::Charge.get')

      Jamm::OpenAPI::PaymentApi.new(Jamm::Client.handler).get_charge(charge_id)
    rescue Jamm::OpenAPI::ApiError => e
      return nil if e.code == 404

      raise Jamm::ApiError.from_error(e)
    end

    # DEPRECATED, use Jamm::Payment.list
    def self.list(customer:, pagination: nil)
      Jamm::Deprecation.warn('Jamm::Charge.list')

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
