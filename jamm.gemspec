# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'jamm/version'

Gem::Specification.new do |s|
  s.name        = 'jamm'
  s.version     = Jamm::VERSION
  s.required_ruby_version = '>= 2.7.0'
  s.summary     = 'Ruby SDK for the Jamm API'
  s.description = 'Jamm help you make payment without credit cards'
  s.authors     = ['Jamm']
  s.email       = 'support@jamm-pay.jp'
  s.homepage    = 'https://jamm-pay.jp'
  s.license     = 'MIT'

  s.add_dependency('rest-client', '~> 2.0')
  s.add_dependency('typhoeus', '~> 1.0', '>= 1.0.1')

  s.files = `git ls-files`.split("\n").reject do |file|
    file.start_with?(
      'examples',
      'images',
      'openapi',
      'pkg',
      'test',
      'Makefile'
    )
  end

  s.test_files    = []
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']

  s.metadata = {
    'source_code_uri' => 'https://github.com/jamm-pay/Jamm-SDK-Ruby'
  }
end
