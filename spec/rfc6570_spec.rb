require 'spec_helper'

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym 'API'
end


Dummy::Application.routes.draw do
  get '/' => 'api#index', as: :root

  get '/path/to/unnamed' => 'api#index', as: nil # Unnamed routes should be ignored

  get '/action' => 'api#action', as: :action

  get '/path/:title' => 'api#index', as: :test1
  get '/path/pp-(:title)-abc' => 'api#index', as: :test2
  get '/path(/:title)' => 'api#index', as: :test3
  get '/path/*capture/:title' => 'api#index', as: :test4
  get '/path(/*capture)/:title' => 'api#index', as: :test5
  get '/path(/*capture)(/:title)' => 'api#index', as: :test6
end

class APIController < ApplicationController
  def index
    render json: rfc6570_routes
  end

  rfc6570_params action: [:param1, :param2]
  def action
    render json: {
      template: action_rfc6570,
      template_url: action_url_rfc6570,
      template_path: action_path_rfc6570,
      partial: test6_rfc6570.partial_expand(title: 'TITLE'),
      expand: test6_rfc6570.expand(capture: %w(a b), title: 'TITLE')
    }
  end
end

describe Rails::RFC6570, type: :request do
  let(:host) { 'http://www.example.com' }
  let(:json) { JSON.parse response.body }

  context 'root' do
    before { get '/' }

    it 'should return list of all parsed and named routes' do
      expect(json.keys).to match_array %w(root action test1 test2 test3 test4 test5 test6)
    end

    it 'should include known parameters' do
      expect(json['action']).to eq "#{host}/action{?param1,param2}"
    end

    it 'should parse capture symbols' do
      expect(json['test1']).to eq "#{host}/path/{title}"
    end

    it 'should parse capture group' do
      expect(json['test2']).to eq "#{host}/path/pp-{title}-abc"
    end

    it 'should parse capture group with slash included' do
      expect(json['test3']).to eq "#{host}/path{/title}"
    end

    it 'should parse splash operator (I)' do
      expect(json['test4']).to eq "#{host}/path{/capture*}/{title}"
    end

    it 'should parse splash operator (II)' do
      expect(json['test5']).to eq "#{host}/path{/capture*}/{title}"
    end

    it 'should parse splash operator (III)' do
      expect(json['test6']).to eq "#{host}/path{/capture*}{/title}"
    end
  end

  context 'action' do
    before { get '/action' }

    it 'should include URL helpers' do
      expect(response.status).to eq 200
    end

    it 'should allow to return and render templates' do
      expect(json['template']).to eq "#{host}/action{?param1,param2}"
    end

    it 'should allow to return and render url templates' do
      expect(json['template_url']).to eq "#{host}/action{?param1,param2}"
    end

    it 'should allow to return and render path templates' do
      expect(json['template_path']).to eq "/action{?param1,param2}"
    end

    it 'should allow to return and render partial expanded templates' do
      expect(json['partial']).to eq "#{host}/path{/capture*}/TITLE"
    end

    it 'should allow to return and render expanded templates' do
      expect(json['expand']).to eq "#{host}/path/a/b/TITLE"
    end
  end
end
