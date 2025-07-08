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
    attr_reader :code, :error_code, :error_type, :message, :headers, :body

    # Add this class method to convert StandardError to ApiError
    def self.from_error(e)
      error_type = Api::ErrorType::UNSPECIFIED

      # Convert Protobuf oriented error to error type.
      details = JSON.parse(e.response_body)['details']

      if details.is_a?(Array) && details.any?
        details.each do |d|
          # Loop through all error types to find a match
          Api::ErrorType.all_vars.each do |type|
            error_type = type.to_s if d['debug'] == type.to_s
          end
        end
      end

      new(
        code: e.code,
        message: e.message,
        error_type: error_type,
        response_headers: e.response_headers,
        response_body: e.response_body
      )
    end

    def initialize(args = {})
      # Check code existence and convert to string if it's integer
      @code = args[:code]
      @message = args[:message]
      @error_type = args[:error_type]
      @headers = args[:response_headers]

      raw_body = if args[:response_body].nil?
                   {}
                 elsif args[:response_body].is_a?(Hash)
                   args[:response_body]
                 elsif args[:response_body].is_a?(String)
                   begin
                     JSON.parse(args[:response_body])
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
