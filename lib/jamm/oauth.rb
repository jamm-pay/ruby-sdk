# frozen_string_literal: true

require 'rest-client'
require 'json'
require 'base64'
require 'jamm/errors'

module Jamm
  module OAuth
    def self.token
      if Jamm.client_id.nil? || Jamm.client_secret.nil?
        raise OAuthError, 'No client_id or client_secret is set. ' \
         'Set your merchant client id and client secret using' \
         'Jamm.client_id=<your client id> and Jamm=<your client secret>'
      end

      fetch_oauth_token(Jamm.client_id, Jamm.client_secret)
    end

    def self.fetch_oauth_token(client_id, client_secret)
      oauth_base = Jamm.oauth_base
      oauth_endpoint = "#{oauth_base}/oauth2/token"
      read_timeout = Jamm.read_timeout
      open_timeout = Jamm.open_timeout

      headers = {
        authorization: "Basic #{Base64.strict_encode64("#{client_id}:#{client_secret}")}",
        content_type: 'application/x-www-form-urlencoded'
      }
      payload = {
        grant_type: 'client_credentials',
        client_id: client_id
      }
      begin
        response = Jamm.execute_request(method: :post, url: oauth_endpoint, payload: payload, headers: headers,
                                        read_timeout: read_timeout, open_timeout: open_timeout)
      rescue SocketError
        raise OAuthError, 'An unexpected error happens while communicating to OAuth server. Check your network setting'
      rescue RestClient::RequestTimeout
        raise OAuthError, "Timed out over #{read_timeout} sec."
      rescue RestClient::ExceptionWithResponse => e
        raise OAuthError.new 'An unsuccessful response was returned', http_status: e.http_code, http_body: e.http_body
      rescue RestClient::Exception => e
        raise OAuthError, "An unexpected error happens while communicating to OAuth server. #{e}"
      end

      parse_oauth_response(response)
    end

    def self.parse_oauth_response(response)
      begin
        body = JSON.parse(response.body)
      rescue JSON::ParserError
        raise OAuthError.new 'Failed to parse the response from the OAuth server', http_status: response.code,
                                                                                   http_body: response.body
      end
      access_token = body['access_token']
      if access_token.nil?
        raise OAuthError.new 'An access token was not found in the response from the OAuth server',
                             http_status: response.code, http_body: response.body
      end

      access_token
    end
  end
end
