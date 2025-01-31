# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rails::RFC6570::Extensions::RouteSet do
  subject(:route_set) do
    ActionDispatch::Routing::RouteSet.new.tap do |routes|
      routes.draw do
        get '/path/:id', to: 'controller#action', as: :test1
      end
    end
  end

  let(:ctx) do
    Class.new do
      def url_options
        {host: 'www.example.org'}
      end
    end.new
  end

  describe '#to_rfc6570' do
    it 'returns dictionary of all named routes' do
      expect(route_set.to_rfc6570(ctx: ctx)).to eq({
        test1: Addressable::Template.new('http://www.example.org/path/{id}'),
      })
    end
  end
end
