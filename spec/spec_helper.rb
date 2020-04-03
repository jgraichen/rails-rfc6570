# frozen_string_literal: true

# Coverage
require 'coveralls'
Coveralls.wear! do
  add_filter 'spec'
end

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('dummy/config/environment', __dir__)
require 'rspec/rails'

Rails.backtrace_cleaner.remove_silencers!

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.expand_path('support/**/*.rb', __dir__)].sort.each {|f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
if defined?(ActiveRecord::Migration) && Rails::VERSION::MAJOR >= 4
  ActiveRecord::Migration.check_pending!
end

RSpec.configure do |config|
  config.order = 'random'
end
