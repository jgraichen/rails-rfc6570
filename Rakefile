# frozen_string_literal: true

require 'rspec/core/rake_task'
require 'rake/release/task'

RSpec::Core::RakeTask.new(:spec)
task default: :spec

Rake::Release::Task.new do |spec|
  spec.sign_tag = true
end
