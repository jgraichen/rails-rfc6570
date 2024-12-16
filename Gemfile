# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'rake'
gem 'rake-release', '~> 1.0'
gem 'rspec', '~> 3.0'

group :development do
  gem 'appraisal'
  gem 'benchmark-ips'
  gem 'pry'
  gem 'pry-byebug'
  gem 'rubocop-config', github: 'jgraichen/rubocop-config', ref: '64e4c81870e869a3bdd9ea3c49fd042b321dbfbd', require: false
end

group :test do
  gem 'rspec-rails'
  gem 'simplecov'
  gem 'simplecov-cobertura'
end
