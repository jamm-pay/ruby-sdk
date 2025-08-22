# frozen_string_literal: true

module Jamm
  module Deprecation
    def self.warn(method)
      puts [
        'DEPRECATION WARNING:',
        "#{method} is going to deprecate.",
        'Please check our migration guide https://github.com/jamm-pay/ruby-sdk/wiki'
      ].join(' ')
    end
  end
end
