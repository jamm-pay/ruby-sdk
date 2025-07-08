# frozen_string_literal: true

module Jamm
  module Client
    def self.handler
      base = Jamm::OpenAPI::ApiClient.new

      # Configure
      base.config.host = Jamm.openapi.config.host
      base.config.scheme = Jamm.openapi.config.scheme
      base.default_headers['Authorization'] = "Bearer #{Jamm::OAuth.token}"

      base
    end
  end
end
