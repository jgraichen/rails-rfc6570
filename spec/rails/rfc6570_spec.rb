# frozen_string_literal: true

require 'spec_helper'

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym 'API'
end

module DummyEngine
  class Engine < ::Rails::Engine
    isolate_namespace DummyEngine

    routes.draw do
      get '/action' => 'engine#action', as: :action
    end
  end

  class EngineController < ActionController::API
    rfc6570_params action: %i[param3]
    def action
      render json: {
        ref: action_path,
        template: action_rfc6570,
        template_url: action_url_rfc6570,
        template_path: action_path_rfc6570,
      }
    end
  end
end

Dummy::Application.routes.draw do
  get '/' => 'api#index', as: :root

  # Unnamed routes should be ignored
  get '/path/to/unnamed' => 'api#index', as: nil

  get '/action' => 'api#action', as: :action

  get '/path/:title' => 'api#index', as: :test1
  get '/path/pp-(:title)-abc' => 'api#index', as: :test2
  get '/path(/:title)' => 'api#index', as: :test3
  get '/path/*capture/:title' => 'api#index', as: :test4
  get '/path(/*capture)/:title' => 'api#index', as: :test5
  get '/path(/*capture)(/:title)' => 'api#index', as: :test6

  mount DummyEngine::Engine => '/dummy_engine'
end

class APIController < ApplicationController
  def index
    render json: rfc6570_routes
  end

  rfc6570_params action: %i[param1 param2]
  def action
    render json: {
      ref: action_url,
      template: action_rfc6570,
      template_url: action_url_rfc6570,
      template_path: action_path_rfc6570,
      partial: test6_rfc6570.partial_expand(title: 'TITLE'),
      ignore: test6_rfc6570(ignore: %w[title]),
      expand: test6_rfc6570.expand(capture: %w[a b], title: 'TITLE'),
      engine_template: dummy_engine.action_rfc6570,
      engine_template_url: dummy_engine.action_url_rfc6570,
      engine_template_path: dummy_engine.action_path_rfc6570,
    }
  end

  def default_url_options
    if (root = request.headers['__OSN']).present?
      super.merge original_script_name: root
    else
      super
    end
  end
end

describe Rails::RFC6570, type: :request do
  let(:host) { 'http://www.example.com' }
  let(:json) { JSON.parse response.body }

  context 'root' do
    before { get '/' }

    it 'returns list of all parsed and named routes' do
      expect(json.keys).to match_array \
        %w[root action test1 test2 test3 test4 test5 test6 dummy_engine]
    end

    it 'includes known parameters' do
      expect(json['action']).to eq "#{host}/action{?param1,param2}"
    end

    it 'parses capture symbols' do
      expect(json['test1']).to eq "#{host}/path/{title}"
    end

    it 'parses capture group' do
      expect(json['test2']).to eq "#{host}/path/pp-{title}-abc"
    end

    it 'parses capture group with slash included' do
      expect(json['test3']).to eq "#{host}/path{/title}"
    end

    it 'parses splash operator (I)' do
      expect(json['test4']).to eq "#{host}/path{/capture*}/{title}"
    end

    it 'parses splash operator (II)' do
      expect(json['test5']).to eq "#{host}/path{/capture*}/{title}"
    end

    it 'parses splash operator (III)' do
      expect(json['test6']).to eq "#{host}/path{/capture*}{/title}"
    end

    it 'includes the engine mount point root only' do
      expect(json['dummy_engine']).to eq "#{host}/dummy_engine"
    end
  end

  context 'action' do
    before { get '/action', headers: headers }

    it 'includes URL helpers' do
      expect(response).to have_http_status :ok
    end

    it 'allows to return and render templates' do
      expect(json['template']).to eq "#{host}/action{?param1,param2}"
    end

    it 'allows to return and render url templates' do
      expect(json['template_url']).to eq "#{host}/action{?param1,param2}"
    end

    it 'allows to return and render path templates' do
      expect(json['template_path']).to eq '/action{?param1,param2}'
    end

    it 'allows to return and render partial expanded templates' do
      expect(json['partial']).to eq "#{host}/path{/capture*}/TITLE"
    end

    it 'allows to return and render expanded templates (I)' do
      expect(json['ignore']).to eq "#{host}/path{/capture*}{.format}"
    end

    it 'allows to return and render expanded templates (II)' do
      expect(json['expand']).to eq "#{host}/path/a/b/TITLE"
    end

    it 'allows to return and render a rails engines templates' do
      expect(json['engine_template']).to eq "#{host}/dummy_engine/action{?param3}"
    end

    it 'allows to return and render a rails engines url templates' do
      expect(json['engine_template_url']).to eq "#{host}/dummy_engine/action{?param3}"
    end

    it 'allows to return and render a rails engines path templates' do
      expect(json['engine_template_path']).to eq '/dummy_engine/action{?param3}'
    end

    context 'with origin_script_name' do
      let(:headers) { {'__OSN' => '/fuubar'} }

      before do
        # Consistency check with normal URL helper
        expect(json['ref']).to eq "#{host}/fuubar/action"
      end

      it 'prefixes origin script name' do
        expect(json['template']).to eq "#{host}/fuubar/action{?param1,param2}"
      end
    end
  end

  context 'mounted Rails engine' do
    before { get '/dummy_engine/action', headers: headers }

    it 'includes URL helpers' do
      expect(response).to have_http_status :ok
    end

    it 'allows to return and render templates' do
      expect(json['template']).to eq "#{host}/dummy_engine/action{?param3}"
    end

    it 'allows to return and render url templates' do
      expect(json['template_url']).to eq "#{host}/dummy_engine/action{?param3}"
    end

    it 'allows to return and render path templates' do
      expect(json['template_path']).to eq '/dummy_engine/action{?param3}'
    end
  end
end
