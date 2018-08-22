# frozen_string_literal: true

require 'benchmark/ips'

require_relative 'base'

ctx = Context.new
route = Rails.application.routes.routes.first

Benchmark.ips do |x|
  x.report('old') do
    ::Rails::RFC6570.build_url_template(ctx, route, path_only: false)
  end

  x.report('new') do
    ::Rails::RFC6570.build_url_template(ctx, route, path_only: false)
  end

  x.hold! '/tmp/benchmark-ips-rfc6570-full.log'
  x.compare!
end
