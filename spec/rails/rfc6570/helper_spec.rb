# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rails::RFC6570::Helper do
  subject(:helper) do
    routes = self.routes

    Class.new do
      def url_options
        {host: 'www.example.org'}
      end

      include routes.url_helpers
      include Rails::RFC6570::Helper
    end.new
  end

  let(:routes) do
    ActionDispatch::Routing::RouteSet.new.tap do |routes|
      routes.draw do
        get '/path/:id', to: 'controller#action', as: :test1
      end
    end
  end

  describe '#rfc6570_routes' do
    it 'returns dictionary of all named routes' do
      expect(helper.rfc6570_routes).to eq({
        test1: Addressable::Template.new('http://www.example.org/path/{id}'),
      })
    end
  end

  describe '#rfc6570_route' do
    it 'returns template for named route' do
      expect(helper.rfc6570_route(:test1)).to eq Addressable::Template.new('http://www.example.org/path/{id}')
    end

    it 'raise KeyError with unknown named route' do
      expect { helper.rfc6570_route(:not_found) }.to raise_error KeyError
    end
  end
end
