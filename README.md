[![MIT License][license-shield]][license-url]

<br />
<div align="center">
  <a href="https://github.com/jamm-pay/Jamm-SDK-Ruby">
    <img src="images/jamm_logo.png" alt="logo" width="120" height="120">
  </a>
  <h3 align="center">Jamm SDK - Ruby</h3>
  <p align="center">
    The official Ruby SDK for Jamm's payment API! We strongly recommend using the SDK for backend integration in order to simplify and streamline your development process!
    <br />
    <a href="https://github.com/jamm-pay/Jamm-SDK-Ruby"><strong>Home »</strong></a>
    <br />
    <br />
    <a href="https://github.com/jamm-pay/Jamm-SDK-Ruby/issues">Report Bug</a>
    ·
    <a href="https://github.com/jamm-pay/Jamm-SDK-Ruby/issues">Request Feature</a>
  </p>
</div>

## How to Use
```ruby
require 'jamm'
Jamm.client_id = '<your client id>'
Jamm.client_secret = '<your client id>'
Jamm.open_timeout = 30 # optionally
Jamm.read_timeout = 90 # optionally
# ex, make a payment
payment = Jamm::Payment.create(
  initial_charge: {
    description: 'Jamm',
    initial_amount: 10_000,
    currency: 'JPY'
  },
  redirect: {
    success_url: 'http://www.example.com/success',
    failure_url: 'http://www.example.com/fail',
    info_url: 'http://www.example.com/customer_service',
    expired_at: "2023-11-07T15:30:00.000+09:00"
  },
  metadata: {
    key1: 'value1',
    key2: 'value2'
  },
  customers: {
    name: "Taro Taro",
    katakanaFirstName: "タロ",
    katakanaLastName: "タロ",
    gender: "MALE",
    postNum: "112-0001",
    address: "東京都渋谷区１−１−１",
    email: "test@jamm-pay.jp",
    phone: "010-1234-5678",
    birthdate: "2000-01-01",
  },
  options: {
    force_kyc: true
  }
)
```

## Errors

Most API calls raise `Jamm::ApiError` on failure, with the HTTP status in `code` and the error type in `api_error_type`
(e.g. `ERROR_TYPE_PAYMENT_VALIDATION_FAILED`). Use `api_error_type`: `error_type` reads
`ERROR_TYPE_UNSPECIFIED` for REST answers and is kept only for compatibility. The generated clients under
`Jamm::OpenAPI` raise `Jamm::OpenAPI::ApiError`; convert it to read the same fields:

```ruby
begin
  Jamm::OpenAPI::PaymentApi.new(Jamm::Client.handler).withdraw(request)
rescue Jamm::OpenAPI::ApiError => e
  raise Jamm::ApiError.from_error(e)
end
```

## Installation
```sh
gem install jamm
```
If you want to build the gem from source:
```sh
gem build jamm.gemspec
```

## API version

Every request to the Jamm API carries a `Jamm-API-Version` header. It defaults to
the dated API version this SDK was built against, exposed as `Jamm::API_VERSION`.
You can pin an older version with `api_version:` in `Jamm.configure`; a newer one
requires upgrading the SDK. Nil or empty means `Jamm::API_VERSION`.

```ruby
Jamm.configure(client_id: '...', client_secret: '...', env: 'production', api_version: '2026-08-26')
```

The API rejects a version it no longer serves; the error lists the versions it does. Responses to a pinned older version follow that version's shape, so fields added since come back empty in this SDK's types.

Every versioned response echoes what served it in two headers:
`Jamm-API-Version` is the version, and `Jamm-API-Version-Source` is how it was
chosen: `header` (the version this SDK sent), `pin` (your account's pinned
version), `default` (no header, and no pin we could read), or `forced` (Jamm
temporarily served its newest shape, which no dated version describes, so
`Jamm-API-Version` is omitted). A request rejected before a version is chosen
carries neither.

OAuth2 token requests are excluded: they go to the identity service, which is
not versioned.

## Development
Test cases can be run with: `bundle exec rake`

### Requirements
* Ruby 2.7.0 or above.
* rest-client

### Built With

[![Ruby][Ruby.com]][Ruby-url]

[license-shield]: https://img.shields.io/badge/license-MIT-blue?style=for-the-badge
[issues-url]: https://github.com/jamm-pay/Jamm-SDK-Ruby/issues
[license-url]: https://github.com/jamm-pay/Jamm-SDK-Ruby/blob/main/LICENSE
[Ruby.com]: https://img.shields.io/badge/ruby-820C02?style=for-the-badge&logo=ruby&logoColor=white
[Ruby-url]: https://ruby-lang.org/en
