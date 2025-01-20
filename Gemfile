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
  gem 'rubocop-config', github: 'jgraichen/rubocop-config', ref: '9f3e5cd0e519811a7f615f265fca81a4f4e843b9', require: false
end

group :test do
  gem 'rspec-rails'
  gem 'simplecov'
  gem 'simplecov-cobertura'
end
