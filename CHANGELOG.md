# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.8.0] - 2026-11-19

### Added

- `Jamm::ApiError#api_error_type`: the error type of any API error, e.g. `ERROR_TYPE_PAYMENT_VALIDATION_FAILED`. Use it instead of `error_type`, which reads `ERROR_TYPE_UNSPECIFIED` for REST answers and is unchanged for compatibility. A type this SDK doesn't know yet is passed through as its string.
- `Jamm::ApiError#charge_id`: the charge ID on an `ERROR_TYPE_PAYMENT_CHARGE_PENDING` answer (outcome not known yet; not returned by the API yet). Retry only with the same `idempotency_key`, or wait for the webhook.
- `Jamm::Payment.off_session(..., idempotency_key:)`: an optional key that makes a sync charge retry-safe once it is enabled for your merchant (until then a request with a key is rejected). Nothing is sent when it is `nil` or blank; unlike `off_session_async`, no key is generated for you.
- `amount_refunded_net_discounts` on the refund webhook `refund` — the amount returned to the buyer for this refund (`amount_refunded` minus its share of the charge discount). Sent on `REFUND_SUCCEEDED` only.

### Fixed

- `Jamm::ApiError.from_error` no longer raises (`TypeError`, `JSON::ParserError` or `NoMethodError`) when the response body is missing, isn't JSON, or isn't a JSON object: a connection timeout has no body, and a proxy error page isn't JSON. The original error is kept.

## [2.7.0] - 2026-10-05

### Added

- Every request to the Jamm API (not OAuth token requests) sends a `Jamm-API-Version` header defaulting to the API version this SDK was built for (`Jamm::API_VERSION`). To stay on an older version, pass `api_version:` to `Jamm.configure`; a newer one needs an SDK upgrade.
- New error type `ERROR_TYPE_PAYMENT_CHARGE_OVER_DAILY_LIMIT`: the charge would exceed the daily limit of the buyer's bank account. Retry after midnight JST.
- Charge webhooks expose `msg.content.metadata`, the map you set when creating the charge, on every charge and refund event. Keys are symbols (`metadata[:order_id]`), and it is `nil` when the charge has none.

### Changed

- The SDK version header is renamed from `X-SDK-Version` to `Jamm-SDK-Version`. If a proxy or firewall allowlists outgoing headers, add `Jamm-SDK-Version`.
- Webhook parsing accepts both `snake_case` and `camelCase` field names, so a future change to the webhook format won't break it.

### Deprecated

- `ERROR_TYPE_CSV_DUPLICATE_USER` is no longer returned.

## [2.6.0] - 2026-07-22

### Fixed

- Restored the forward-compatible `Jamm::Webhook.parse` first shipped in 2.3.0 (2.4.0 and 2.5.0 regressed to strict parsing):
  - Webhook parsing no longer fails on new fields added by the backend (unknown fields are ignored instead of raising `ArgumentError`)
  - Numeric enum wire values (`status`, …) resolve onto their string enum constants, matching REST API responses
  - Refund webhooks expose the nested transaction fields, the refund's `rfd-` id (`refund_id` and `refund.id`), and typed nested models (`refund.error.code` works instead of raising `NoMethodError`)
  - `EVENT_TYPE_USER_ACCOUNT_DELETED` webhooks parse (previously raised `Unknown event type`)
  - `Webhook.parse` accepts payloads with either string or symbol keys
- `Webhook.parse` routes on the coerced event type, so event routing also survives a numeric `event_type` wire value

## [2.5.0] - 2026-07-03

### Added

- Added `Jamm::Webhook.verify_and_parse(raw_body)` — verifies the HMAC signature over the exact received `content` bytes and parses in one step. Unlike `Jamm::Webhook.verify`, it is not broken by JSON re-serialization (correctly handles `&`, `<`, `>` in content) and rejects bodies with duplicate top-level keys.

## [2.4.0] - 2026-07-01

### Added

- Send the `X-SDK-Version` request header (`ruby:<version>`) so the backend can track SDK version usage per merchant

## [2.2.0] - 2026-05-20

### Added

- Added `Jamm::Payment.off_session_async` for async off-session charges
- Auto-fill `idempotency_key` with a UUID when `nil` or blank

## [2.1.0] - 2026-04-06

### Added

- Added `ChargeError` details on `ChargeResult` for failed charges

## [2.0.0] - 2026-03-16

### Added

- Platform authentication support
- Refund support and split refund webhook events (succeeded / rejected)

### Changed

- Renamed `cancel` operations to `refund` across API and webhooks

## [1.7.0] - 2025-11-11

### Removed

- Deprecated legacy contract charge public APIs

## [1.6.0] - 2025-11-11

### Changed

- Version bump aligned with other SDKs

## [1.5.0] - 2025-10-09

### Changed

- `OnSessionPayment` redirect link is now optional

## [1.4.1] - 2025-08-22

### Changed

- Updated RubyGem GitHub source URL

## [1.4.0] - 2025-08-22

### Added

- On-session and off-session payment support

## [1.3.0] - 2025-07-08

### Added

- Embedded `error.v1` typed errors into OpenAPI proto
