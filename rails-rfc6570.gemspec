# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rails/rfc6570/version'

Gem::Specification.new do |spec|
  spec.name          = 'rails-rfc6570'
  spec.version       = Rails::RFC6570::VERSION
  spec.authors       = ['Jan Graichen']
  spec.email         = ['jgraichen@altimos.de']
  spec.summary       = 'Pragmatical access to your Rails routes as ' \
                       'RFC6570 URI templates.'
  spec.homepage      = 'https://github.com/jgraichen/rails-rfc6570'
  spec.license       = 'MIT'

  spec.files         = Dir['**/*'].grep(%r{^(
      (bin|lib|test|spec|features)/|
      (.*\.gemspec|.*LICENSE.*|.*README.*|.*CHANGELOG.*)
    )}x)
  spec.executables   = spec.files.grep(%r{^bin/}) {|f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'actionpack', '>= 4.2', '< 6.2'
  spec.add_runtime_dependency 'addressable', '~> 2.3'

  spec.add_development_dependency 'bundler'
end
