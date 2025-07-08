[![MIT License][license-shield]][license-url]

<br />
<div align="center">
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

## Installation
```sh
gem install jamm
```
If you want to build the gem from source:
```sh
gem build jamm.gemspec
```

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
