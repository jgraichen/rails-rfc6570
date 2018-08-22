# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../spec/dummy/config/environment', __dir__)

class TestController
  extend ::Rails::RFC6570::ControllerExtension
  rfc6570_params index: %w[queryA queryB]
end

Rails.application.routes.draw do
  get '/path(/*capture)/:title' => 'test#index', as: :test
end

class Context
  include Rails.application.routes.url_helpers

  def url_options
    {host: 'example.org'}
  end
end
