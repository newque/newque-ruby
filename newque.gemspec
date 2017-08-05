# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'newque/version'

Gem::Specification.new do |gem|
  gem.name          = 'write_xlsx'
  gem.version       = Newque::VERSION
  gem.authors       = ['Simon Grondin']
  gem.email         = ['simon.grondin@outlook.com']
  gem.description   = 'Ruby Client library for Newque'
  gem.summary       = 'Ruby Client library for Newque'
  gem.homepage      = 'http://github.com/newque/newque-ruby'
  gem.license       = 'MPL-2.0'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = []
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.required_ruby_version = '>= 2.0.0'

  gem.add_dependency 'beefcake', '~> 1.2.0'
  gem.add_dependency 'ffi-rzmq', '~> 2.0.5'
  gem.add_dependency 'faraday', '~> 0.12.2'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'pry'

  gem.extra_rdoc_files = [
    'LICENSE',
    'README.md'
  ]
end
