# frozen_string_literal: true

require 'openssl'
require 'rest-client'
require 'json'
require 'base64'
require 'jamm/errors'

module Jamm
  module Webhook
    # Parse command is for parsing the received webhook message.
    # It does not call anything remotely, instead returns the suitable object.
    def self.parse(json)
      # Webhook payloads may arrive with string or symbol keys depending on how
      # the caller decoded the JSON (e.g. JSON.parse with or without
      # symbolize_names: true). Normalize to symbols so event-type routing,
      # wrapper flattening, and field lookups are reliable either way.
      json = deep_symbolize_keys(json)

      out = build(Jamm::OpenAPI::MerchantWebhookMessage, json)

      # Route on the coerced event type: the wire value is an enum string today,
      # but `build` also resolves a numeric wire value onto its string constant,
      # so routing survives either serialization.
      case out.event_type
      when Jamm::OpenAPI::EventType::CHARGE_CREATED,
           Jamm::OpenAPI::EventType::CHARGE_UPDATED,
           Jamm::OpenAPI::EventType::REFUND_SUCCEEDED,
           Jamm::OpenAPI::EventType::REFUND_FAILED,
           Jamm::OpenAPI::EventType::CHARGE_SUCCESS,
           Jamm::OpenAPI::EventType::CHARGE_FAIL
        out.content = build(Jamm::OpenAPI::ChargeMessage, flatten_charge_content(json[:content]))
        return out

      when Jamm::OpenAPI::EventType::CONTRACT_ACTIVATED
        out.content = build(Jamm::OpenAPI::ContractMessage, json[:content])
        return out

      when Jamm::OpenAPI::EventType::USER_ACCOUNT_DELETED
        out.content = build(Jamm::OpenAPI::UserAccountMessage, json[:content])
        return out
      end

      raise 'Unknown event type'
    end

    # Build a generated model from a webhook payload while normalizing the
    # quirks of the webhook wire format. Applied to every model, so charges,
    # contracts, user-account and refund messages all benefit:
    #
    #   1. Forward-compat: the Jamm backend can add new fields to webhook
    #      payloads at any time. The generated model `initialize` raises
    #      ArgumentError on any key outside `attribute_map`, so unknown keys are
    #      dropped first. Known keys are snake_case, matching `attribute_map`.
    #   2. Numeric enums: the backend serializes webhook payloads with Go's
    #      `json.Marshal` (not protojson), so every enum field (status,
    #      api_source, ...) arrives as its integer value, while the generated
    #      enums are string-based. Each integer is mapped back to the enum string
    #      so it matches the values returned by the REST API.
    #   3. Nested models: the generated `initialize` assigns nested objects
    #      verbatim (the `_deserialize` coercion only runs from `build_from_hash`,
    #      which expects camelCase keys the webhook does not use). So a nested
    #      field like `refund.error` would stay a raw Hash and `error.code` would
    #      raise NoMethodError. We coerce nested model fields (and arrays of them)
    #      recursively so the typed accessors work.
    def self.build(klass, attributes)
      return nil if attributes.nil?

      known = klass.attribute_map
      types = klass.openapi_types
      filtered = attributes.each_with_object({}) do |(key, value), acc|
        sym = key.to_sym
        next unless known.key?(sym)

        acc[sym] = coerce(types[sym], value)
      end

      klass.new(filtered)
    end

    # Refund webhooks (REFUND_SUCCEEDED / REFUND_FAILED) deliver `content` as a
    # nested { transaction, refund } wrapper instead of a flat ChargeMessage.
    # Flatten it back into a ChargeMessage so callers always receive the same shape.
    def self.flatten_charge_content(content)
      return content unless content.is_a?(Hash) && content.key?(:transaction)

      refund = content[:refund]
      # Keep `refund` as the raw Hash: `build` coerces it into a typed RefundInfo
      # (and recursively types its nested `error`). Also surface the refund's
      # `rfd-` id on the flat `refund_id` attribute the model documents.
      charge = content[:transaction].merge(refund: refund)
      charge[:refund_id] = refund[:id] if refund.is_a?(Hash) && !refund[:id].nil?
      charge
    end

    # Coerce a raw webhook value into the shape the generated model expects,
    # based on the field's openapi type: numeric enums become their string
    # constant, nested models become typed instances, and `Array<T>` elements are
    # coerced by `T`. Anything else passes through untouched.
    def self.coerce(type, value)
      return value if value.nil?

      inner = array_inner_type(type)
      return coerce_array(inner, value) unless inner.nil?

      klass = openapi_const(type)
      return value if klass.nil?

      if klass.respond_to?(:all_vars)
        resolve_enum(klass, value)
      elsif klass.respond_to?(:openapi_types) && value.is_a?(Hash)
        build(klass, value)
      else
        value
      end
    end

    # Coerce each element of an `Array<T>` field by its inner type `T`.
    def self.coerce_array(inner_type, value)
      return value unless value.is_a?(Array)

      value.map { |element| coerce(inner_type, element) }
    end

    # Extract `T` from an `Array<T>` openapi type, or nil when not an array type.
    def self.array_inner_type(type)
      match = type.to_s.match(/\AArray<(.+)>\z/)
      match && match[1]
    end

    # Map a numeric enum wire value onto its string enum constant. A value that
    # is already a string (REST-style) passes through untouched.
    def self.resolve_enum(enum, value)
      return value unless value.is_a?(Integer)

      vars = enum.all_vars
      # Guard the bounds explicitly: Ruby maps negative indices from the end of
      # the array, so any unexpected wire value must fall back to the *_UNSPECIFIED
      # member (index 0) rather than silently selecting the wrong constant.
      value.between?(0, vars.length - 1) ? vars[value] : vars[0]
    end

    # Resolve an openapi_types entry (e.g. :ChargeMessageApiSource, :RefundInfo)
    # to its generated class, or nil when the type is a primitive (String,
    # Integer, ...) or otherwise unresolvable.
    def self.openapi_const(type)
      return nil if type.nil?

      name = type.to_s
      return nil unless Jamm::OpenAPI.const_defined?(name)

      Jamm::OpenAPI.const_get(name)
    rescue NameError
      nil
    end

    # Recursively convert Hash keys to symbols so parsing is robust regardless of
    # how the caller decoded the webhook JSON.
    def self.deep_symbolize_keys(value)
      case value
      when Hash
        value.each_with_object({}) { |(k, v), acc| acc[k.to_sym] = deep_symbolize_keys(v) }
      when Array
        value.map { |v| deep_symbolize_keys(v) }
      else
        value
      end
    end

    # Verify message.
    # This method will use client secret to verify the message.
    def self.verify(data:, signature:)
      raise ArgumentError, 'data cannot be nil' if data.nil?
      raise ArgumentError, 'signature cannot be nil' if signature.nil?

      # Convert the JSON to a string
      json = JSON.dump(data)

      digest = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), Jamm.client_secret, json)
      given = "sha256=#{digest}"

      return if secure_compare(given, signature)

      raise Jamm::InvalidSignatureError, 'Digests do not match'
    end

    # Verify the HMAC signature over the exact received bytes and parse, in one step.
    #
    # This is the recommended entry point. The backend signs the raw +content+ bytes it
    # transmits, produced by Go's JSON encoder which HTML-escapes & < > as & <
    # >. Re-serializing the parsed content (as +verify+ does via JSON.dump) un-escapes
    # those characters, so its digest no longer matches. This slices the raw +content+
    # substring out of +raw_body+ verbatim and HMACs that.
    def self.verify_and_parse(raw_body)
      raise ArgumentError, 'raw_body cannot be nil or empty' if raw_body.nil? || raw_body.empty?

      parsed = JSON.parse(raw_body, symbolize_names: true)
      signature = parsed[:signature]
      raise ArgumentError, "Webhook body is missing the 'signature' field" if signature.nil? || signature.empty?

      raw_content = extract_raw_content(raw_body)
      digest = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), Jamm.client_secret, raw_content)
      given = "sha256=#{digest}"
      raise Jamm::InvalidSignatureError, 'Digests do not match' unless secure_compare(given, signature)

      parse(parsed)
    end

    # Extracts the top-level +content+ value substring from a raw webhook body verbatim,
    # without decoding or re-serializing it, so the exact signed bytes are recovered.
    def self.extract_raw_content(raw_body)
      i = 0
      n = raw_body.length
      i += 1 while i < n && raw_body[i].match?(/\s/)
      raise ArgumentError, 'Webhook body must be a JSON object' unless raw_body[i] == '{'

      i += 1
      # Scan every top-level key. Duplicate keys are rejected: JSON.parse keeps the LAST
      # occurrence while this returns the FIRST, so a duplicate `content` could otherwise
      # verify one payload and parse another (signature bypass).
      seen = {}
      content = nil
      loop do
        i += 1 while i < n && (raw_body[i].match?(/\s/) || raw_body[i] == ',')
        break if i >= n || raw_body[i] == '}'
        raise ArgumentError, 'Malformed webhook JSON' unless raw_body[i] == '"'

        key_start = i
        i = skip_string(raw_body, i)
        # Decode the key (not a raw slice): otherwise an escaped duplicate such as
        # "content" would evade both the duplicate check and the 'content' match below,
        # while JSON.parse collapses it to `content` and keeps the last value. Normalize a
        # malformed key to ArgumentError to match the rest of this method.
        key = begin
          JSON.parse(raw_body[key_start...i])
        rescue JSON::ParserError
          raise ArgumentError, 'Malformed webhook JSON'
        end
        raise ArgumentError, "Duplicate top-level key in webhook body: #{key}" if seen.key?(key)

        seen[key] = true
        i += 1 while i < n && raw_body[i].match?(/\s/)
        raise ArgumentError, 'Malformed webhook JSON' unless raw_body[i] == ':'

        i += 1
        i += 1 while i < n && raw_body[i].match?(/\s/)
        value_start = i
        i = skip_value(raw_body, i)
        content = raw_body[value_start...i] if key == 'content'
      end
      raise ArgumentError, "Webhook body does not contain 'content' field" if content.nil?

      content
    end

    # +i+ points at an opening '"'. Returns the index just past the closing '"'.
    def self.skip_string(str, i)
      i += 1
      n = str.length
      while i < n
        c = str[i]
        if c == '\\'
          i += 2
          next
        end
        return i + 1 if c == '"'

        i += 1
      end
      raise ArgumentError, 'Unterminated string in webhook JSON'
    end

    # +i+ points at the first char of a JSON value. Returns the index just past it.
    def self.skip_value(str, i)
      return skip_string(str, i) if str[i] == '"'

      if str[i] == '{' || str[i] == '['
        depth = 0
        n = str.length
        while i < n
          ch = str[i]
          if ch == '"'
            i = skip_string(str, i)
            next
          elsif ch == '{' || ch == '['
            depth += 1
          elsif ch == '}' || ch == ']'
            depth -= 1
            return i + 1 if depth.zero?
          end
          i += 1
        end
        raise ArgumentError, 'Unterminated object/array in webhook JSON'
      end
      i += 1 while i < str.length && !",}] \t\n\r".include?(str[i])
      i
    end

    # Securely compare two strings of equal length.
    # This method is a port of ActiveSupport::SecurityUtils.secure_compare
    # which works on non-Rails platforms.
    def self.secure_compare(a, b)
      return false unless a.bytesize == b.bytesize

      # Unpack strings into arrays of bytes
      a_bytes = a.unpack('C*')
      b_bytes = b.unpack('C*')
      result = 0

      # XOR each byte and accumulate the result
      a_bytes.zip(b_bytes) { |x, y| result |= x ^ y }
      result.zero?
    end
  end
end
