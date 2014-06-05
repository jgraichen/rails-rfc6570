# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rails/rfc6570/version'

Gem::Specification.new do |spec|
  spec.name          = 'rails-rfc6570'
  spec.version       = Rails::RFC6570::VERSION
  spec.authors       = ['Jan Graichen']
  spec.email         = ['jg@altimos.de']
  spec.summary       = %q(Pragmatical access to your Rails routes as RFC6570 URI templates.)
  spec.description   = %q(Pragmatical access to your Rails routes as RFC6570 URI templates.)
  spec.homepage      = 'https://github.com/jgraichen/rails-rfc6570'
  spec.license       = 'MIT'

  spec.files         = Dir['**/*'].grep(/^(
      (bin|lib|test|spec|features)\/|
      (.*\.gemspec|.*LICENSE.*|.*README.*|.*CHANGELOG.*)
    )/x)
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'actionpack', '>= 3.2', '< 5'
  spec.add_runtime_dependency 'addressable', '~> 2.3'

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake'
end
