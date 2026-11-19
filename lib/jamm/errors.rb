# frozen_string_literal: true

require 'jamm/api/models/v1_error_type'

module Jamm
  class JammError < StandardError
    attr_reader :message, :http_body, :http_headers, :http_status, :json_body

    def initialize(message = nil, http_status: nil, http_headers: nil, http_body: nil, json_body: nil)
      super(message)

      @message = message
      @http_status = http_status
      @http_headers = http_headers
      @http_body = http_body
      @json_body = json_body
    end

    def to_s
      status_string = @http_status.nil? ? '' : "(Status #{@http_status}) "
      "#{status_string}#{@message}"
    end
  end

  # OAuthError is raised when a request to AWS cognito failed
  class OAuthError < JammError
  end

  class InvalidSignatureError < StandardError
  end

  # Purpose of this error handler is to normalize Jamm's custom error
  # and OpenAPI's generated error, and enforce Jamm's custom error format.
  #
  # - Jamm:    code is string, message is string originating from Jamm's protobuf definition.
  # - OpenAPI: code is integer, message is string originating from ConnectRPC error format.
  class ApiError < StandardError
    # error_type is kept for compatibility (it reads ERROR_TYPE_UNSPECIFIED for REST answers); use api_error_type.
    attr_reader :code, :error_code, :error_type, :api_error_type, :charge_id, :message, :headers, :body

    VALUE_DETAIL = 'type.googleapis.com/google.protobuf.Value'
    CHARGE_PENDING_DETAIL = 'type.googleapis.com/api.v1.ChargePendingDetail'
    private_constant :VALUE_DETAIL, :CHARGE_PENDING_DETAIL

    # Add this class method to convert StandardError to ApiError
    def self.from_error(e)
      details = parse_details(e.response_body)

      new(
        code: e.code,
        message: e.message,
        error_type: legacy_error_type_from(details),
        api_error_type: api_error_type_from(details),
        charge_id: charge_id_from(details),
        response_headers: e.response_headers,
        response_body: e.response_body
      )
    end

    # A connection timeout has no body, and a proxy error page isn't JSON: keep the real error.
    def self.parse_details(body)
      parsed = body.is_a?(Hash) ? body : JSON.parse(body.to_s)
      return [] unless parsed.is_a?(Hash) && parsed['details'].is_a?(Array)

      parsed['details'].select { |d| d.is_a?(Hash) }
    rescue JSON::ParserError, TypeError
      []
    end

    # error_type keeps its historic rule (a known type in `debug`), which REST answers never match.
    def self.legacy_error_type_from(details)
      error_type = Api::ErrorType::UNSPECIFIED
      details.each do |d|
        Api::ErrorType.all_vars.each { |type| error_type = type.to_s if d['debug'] == type.to_s }
      end
      error_type
    end

    # REST answers carry the type as a google.protobuf.Value detail, Connect as `debug`.
    # An unknown ERROR_TYPE_* passes through, so a newer server's type isn't lost.
    def self.api_error_type_from(details)
      details.each do |d|
        type = d['@type'] == VALUE_DETAIL ? d['value'] : d['debug']
        return type if type.is_a?(String) && type.start_with?('ERROR_TYPE_')
      end
      Api::ErrorType::UNSPECIFIED
    end

    # The charge ID of a pending sync charge (outcome unknown): retry only with the same idempotency_key.
    def self.charge_id_from(details)
      pending = details.find { |d| d['@type'] == CHARGE_PENDING_DETAIL }
      id = pending && pending['chargeId']
      id.is_a?(String) && !id.empty? ? id : nil
    end
    private_class_method :parse_details, :legacy_error_type_from, :api_error_type_from, :charge_id_from

    def initialize(args = {})
      # Check code existence and convert to string if it's integer
      @code = args[:code]
      @message = args[:message]
      @error_type = args[:error_type]
      @api_error_type = args[:api_error_type]
      @charge_id = args[:charge_id]
      @headers = args[:response_headers]

      raw_body = if args[:response_body].nil?
                   {}
                 elsif args[:response_body].is_a?(Hash)
                   args[:response_body]
                 elsif args[:response_body].is_a?(String)
                   begin
                     parsed = JSON.parse(args[:response_body])
                     parsed.is_a?(Hash) ? parsed : {}
                   rescue StandardError
                     {}
                   end
                 else
                   {}
                 end

      @body = {}
      raw_body.each do |k, v|
        next if k == 'code'

        @body[k.to_sym] = v if k.respond_to?(:to_sym)
      end

      # Set human readable error type based on error code
      # https://github.com/connectrpc/connect-go/blob/d7c0966751650b41a9f1794513592e81b9beed45/code.go#L34
      @body[:error] = case raw_body['code']
                      when 1
                        'CANCELED'
                      when 2
                        'UNKNOWN'
                      when 3
                        'INVALID_ARGUMENT'
                      when 4
                        'DEADLINE_EXCEEDED'
                      when 5
                        'NOT_FOUND'
                      when 6
                        'ALREADY_EXISTS'
                      when 7
                        'PERMISSION_DENIED'
                      when 8
                        'RESOURCE_EXHAUSTED'
                      when 9
                        'FAILED_PRECONDITION'
                      when 10
                        'ABORTED'
                      when 11
                        'OUT_OF_RANGE'
                      when 12
                        'UNIMPLEMENTED'
                      when 13
                        'INTERNAL'
                      when 14
                        'UNAVAILABLE'
                      when 15
                        'DATA_LOSS'
                      when 16
                        'UNAUTHENTICATED'
                      end

      super(message)
    end

    def to_s
      status_string = @code.nil? ? '' : "(Status #{@code}) "
      "#{status_string}#{@message}"
    end
  end

  # ErrorType is a wrapper around Api::ErrorType to encapsulate OpenAPI related constants.
  class ErrorType
    # Dynamically copy constants from Api::ErrorType
    Api::ErrorType.constants(false).each do |const_name|
      const_set(const_name, Api::ErrorType.const_get(const_name))
    end
  end
end
