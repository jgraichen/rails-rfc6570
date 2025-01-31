# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rails::RFC6570::Visitor do
  subject(:accept) { visitor.accept(node) }

  let(:visitor) { described_class.new }
  let(:node) { ActionDispatch::Journey::Parser.new.parse(path) }

  describe '/' do
    let(:path) { '/' }

    it { is_expected.to eq %w[/] }
  end

  describe '/path/path' do
    let(:path) { '/path/path' }

    it { is_expected.to eq %w[/ path / path] }
  end

  describe '/path.:format' do
    let(:path) { '/path.:format' }

    it { is_expected.to eq %w[/ path . {format}] }
  end

  describe '/:title' do
    let(:path) { '/:title' }

    it { is_expected.to eq %w[/ {title}] }
  end

  describe '/:title.html' do
    let(:path) { '/:title.html' }

    it { is_expected.to eq %w[/ {title} . html] }
  end

  describe '/:title(.:format)' do
    let(:path) { '/:title(.:format)' }

    it { is_expected.to eq %w[/ {title} {.format}] }
  end

  describe '/path/:title' do
    let(:path) { '/path/:title' }

    it { is_expected.to eq %w[/ path / {title}] }
  end

  describe '/path/pre-(:id)-post' do
    let(:path) { '/path/pre-(:id)-post' }

    it { is_expected.to eq %w[/ path / pre- {id} -post] }
  end

  describe '/path(/:title)' do
    let(:path) { '/path(/:title)' }

    it { is_expected.to eq %w[/ path {/title}] }
  end

  describe '/path/*capture/:title' do
    let(:path) { '/path/*capture/:title' }

    it { is_expected.to eq %w[/ path {/capture*} / {title}] }
  end

  describe '/path(/*capture)/:title' do
    let(:path) { '/path(/*capture)/:title' }

    it { is_expected.to eq %w[/ path {/capture*} / {title}] }
  end

  describe '/path(/*capture)(/:title)' do
    let(:path) { '/path(/*capture)(/:title)' }

    it { is_expected.to eq %w[/ path {/capture*} {/title}] }
  end

  describe '*a/path/*b' do
    let(:path) { '*a/path/*b' }

    it { is_expected.to eq %w[{/a*} / path {/b*}] }
  end

  describe 'path/*a/path/*b' do
    let(:path) { 'path/*a/path/*b' }

    it { is_expected.to eq %w[path {/a*} / path {/b*}] }
  end

  describe 'path/*a/*b' do
    let(:path) { 'path/*a/*b' }

    it { is_expected.to eq %w[path {/a*} {/b*}] }
  end

  describe 'path/*a/:title' do
    let(:path) { 'path/*a/:title' }

    it { is_expected.to eq %w[path {/a*} / {title}] }
  end

  describe 'path/*a(/:title)' do
    let(:path) { 'path/*a(/:title)' }

    it { is_expected.to eq %w[path {/a*} {/title}] }
  end

  describe '/(:title)' do
    let(:path) { '/(:title)' }

    it { is_expected.to eq %w[/ {title}] }
  end

  describe '(/:title)' do
    let(:path) { '(/:title)' }

    it { is_expected.to eq %w[{/title}] }
  end

  describe '(/:title/)' do
    let(:path) { '(/:title/)' }

    it { is_expected.to eq %w[{/title} /] }
  end

  describe '(/:a(/:b))' do
    let(:path) { '(/:a(/:b))' }

    it { is_expected.to eq %w[{/a} {/b}] }
  end

  describe '(/a)|(/b)' do
    let(:path) { '(/a)|(/b)' }

    it do
      expect { accept }.to \
        raise_error 'OR nodes cannot be serialized to URI templates'
    end
  end
end
