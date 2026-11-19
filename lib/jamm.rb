# frozen_string_literal: true

require 'date'
require 'rest-client'
require 'openssl'
require 'json'

require 'jamm/api_version'
require 'jamm/client'
require 'jamm/errors'
require 'jamm/oauth'
require 'jamm/openapi'
require 'jamm/version'

# OpenAPI wrappers
require 'jamm/customer'
require 'jamm/deprecation'
require 'jamm/healthcheck'
require 'jamm/payment'
require 'jamm/webhook'

# Patches
require 'jamm/api_patches'

# Jamm Ruby SDK
module Jamm
  # SDK mode, either platform or merchant.
  module Mode
    PLATFORM = 'platform'
    MERCHANT = 'merchant'
  end

  # Configurable attributes.
  @environment = nil
  @mode = nil
  @oauth_base = nil
  @openapi = nil
  @open_timeout = 30
  @read_timeout = 90
  @max_retry = 0

  class << self
    attr_accessor :api, :client_id, :client_secret, :api_base, :environment, :mode, :oauth_base, :connect_base,
                  :openapi, :open_timeout, :read_timeout, :max_retry, :retry_initial_delay, :retry_max_delay
  end

  # The Jamm-API-Version sent on every request; defaults to the version this SDK was built against.
  def self.api_version
    @api_version || Jamm::API_VERSION
  end

  def self.api_version=(version)
    if version.nil? || version.to_s.empty?
      @api_version = nil
      return
    end

    version = version.to_s
    raise ArgumentError, "invalid api_version \"#{version}\": expected YYYY-MM-DD" unless version.match?(/\A\d{4}-\d{2}-\d{2}\z/) && Date.valid_date?(*version.split('-').map(&:to_i))
    raise ArgumentError, "api_version #{version} is newer than this SDK supports (#{Jamm::API_VERSION}); upgrade the SDK to use it" if version > Jamm::API_VERSION

    @api_version = version
  end

  # Configure SDK with Client ID and Secret.
  # Optionally enable `platform` for platformers to call Jamm API on behalf of their merchant.
  # Optionally pin `api_version` (YYYY-MM-DD) to an API version older than the one this SDK was built against.
  def self.configure(client_id:, client_secret:, env:, platform: false, api_version: nil)
    self.api_version = api_version
    Jamm.client_id = client_id
    Jamm.client_secret = client_secret

    Jamm.mode = platform ? Jamm::Mode::PLATFORM : Jamm::Mode::MERCHANT

    case env
    when 'prd', 'prod', 'production'
      self.oauth_base = Jamm.mode == Jamm::Mode::PLATFORM ? 'https://platform-identity.jamm-pay.jp' : 'https://merchant-identity.jamm-pay.jp'

      self.environment = 'production'
      self.openapi = Jamm::OpenAPI::ApiClient.new
      openapi.config.host = 'api.jamm-pay.jp'

    when 'local'
      self.oauth_base = Jamm.mode == Jamm::Mode::PLATFORM ? 'https://platform-identity.develop.jamm-pay.jp' : 'https://merchant-identity.develop.jamm-pay.jp'

      self.environment = 'local'
      self.openapi = Jamm::OpenAPI::ApiClient.new
      openapi.config.host = 'api.jamm.test'
      openapi.config.verify_ssl = false
      openapi.config.verify_ssl_host = false
    else
      self.oauth_base = Jamm.mode == Jamm::Mode::PLATFORM ? "https://platform-identity.#{env}.jamm-pay.jp" : "https://merchant-identity.#{env}.jamm-pay.jp"

      self.environment = env
      self.openapi = Jamm::OpenAPI::ApiClient.new
      openapi.config.host = "api.#{env}.jamm-pay.jp"
    end

    openapi.config.scheme = 'https'
  end

  def self.execute_request(option)
    RestClient::Request.execute(option)
  end
end
