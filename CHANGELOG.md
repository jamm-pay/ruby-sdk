# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
