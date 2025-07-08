# frozen_string_literal: true

require 'rest-client'
require 'openssl'
require 'json'

require 'jamm/client'
require 'jamm/errors'
require 'jamm/oauth'
require 'jamm/openapi'
require 'jamm/version'

# OpenAPI wrappers
require 'jamm/charge'
require 'jamm/customer'
require 'jamm/contract'
require 'jamm/healthcheck'
require 'jamm/webhook'

# Patches
require 'jamm/api_patches'

# Jamm Ruby SDK
module Jamm
  # Configurable attributes.
  @oauth_base = nil
  @openapi = nil
  @open_timeout = 30
  @read_timeout = 90
  @max_retry = 0

  class << self
    attr_accessor :api, :client_id, :client_secret, :api_base, :env, :oauth_base, :api_version, :connect_base,
                  :openapi, :open_timeout, :read_timeout, :max_retry, :retry_initial_delay, :retry_max_delay
  end

  def self.configure(client_id:, client_secret:, env:)
    Jamm.client_id = client_id
    Jamm.client_secret = client_secret

    case env
    when 'prd', 'prod', 'production'
      self.oauth_base = 'https://merchant-identity.jamm-pay.jp'

      self.openapi = Jamm::OpenAPI::ApiClient.new
      openapi.config.host = 'api.jamm-pay.jp'

    when 'local'
      self.oauth_base = 'https://merchant-identity.develop.jamm-pay.jp'

      self.openapi = Jamm::OpenAPI::ApiClient.new
      openapi.config.host = 'api.jamm.test'
      openapi.config.verify_ssl = false
      openapi.config.verify_ssl_host = false
    else
      self.oauth_base = "https://merchant-identity.#{env}.jamm-pay.jp"

      self.openapi = Jamm::OpenAPI::ApiClient.new
      openapi.config.host = "api.#{env}.jamm-pay.jp"
    end

    openapi.config.scheme = 'https'
  end

  def self.execute_request(option)
    RestClient::Request.execute(option)
  end
end
