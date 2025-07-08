# frozen_string_literal: true

require 'rest-client'
require 'json'
require 'base64'
require 'jamm/errors'

module Jamm
  module Healthcheck
    def self.ping
      Jamm::OpenAPI::HealthcheckApi.new(Jamm::Client.handler).ping
    rescue Jamm::OpenAPI::ApiError => e
      raise Jamm::ApiError.from_error(e)
    end
  end
end
