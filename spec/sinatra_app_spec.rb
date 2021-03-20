# frozen_string_literal: true

require_relative 'spec_helper'
require 'json'
require 'ougai'
require 'rack/test'
require 'active_support/core_ext/hash/keys'
require_relative 'github_webhook_helper'
require_relative '../lib/app/sinatra_app'
require_relative '../lib/github_api_types'
require_relative '../lib/factory'
require_relative '../lib/state_store/memory_store'

describe Pulljoy::WebApp do
  include Rack::Test::Methods

  let(:event_handler_factory) { Pulljoy::Factory.new(Pulljoy::EventHandler) }

  let(:logger) do
    logger = Ougai::Logger.new($stderr)
    logger.level = :fatal
    logger
  end

  let(:app) do
    Pulljoy::WebApp.set :environment, 'test'
    Pulljoy::WebApp.activate_pulljoy_config(PULLJOY_TEST_CONFIG)
    Pulljoy::WebApp.new(
      logger: logger,
      event_handler_factory: event_handler_factory,
      state_store: Pulljoy::StateStore::MemoryStore.new,
    )
  end

  let(:app_instance) { app.instance_variable_get(:@instance) }

  def last_json_body
    JSON.parse(last_response.body).deep_symbolize_keys
  end

  specify '/ping works' do
    get '/ping'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('pong')
  end

  describe '/receive_github_event' do
    let(:pr_open_event) do
      Pulljoy::PullRequestEvent.new(
        action: Pulljoy::PullRequestEvent::ACTION_OPENED,
        repository: {
          full_name: 'foo/foo',
        },
        user: {
          login: 'foo',
        },
        pull_request: {
          number: 123,
          head: {
            sha: 'modified',
            repo: {
              full_name: 'foo/fork',
            },
          },
          base: {
            sha: 'original',
            repo: {
              full_name: 'foo/foo',
            },
          },
        },
      )
    end

    it 'responds to pings' do
      post '/receive_github_event', nil, 'HTTP_X_GITHUB_EVENT' => 'ping'
      expect(last_response).to be_ok
      expect(last_json_body).to eq(processed: true)
    end

    it 'errors upon receiving an unsupported event type' do
      post(
        '/receive_github_event',
        '{}',
        'HTTP_X_GITHUB_EVENT' => 'foo',
        'HTTP_X_HUB_SIGNATURE' => create_github_webhook_signature('{}'),
      )
      expect(last_response.status).to eq(422)
      expect(last_json_body).to eq(
        processed: false,
        message: 'Unsupported event type "foo"',
      )
    end

    it 'accepts a supported event type' do
      event_handler = double('EventHandler')
      expect(event_handler).to receive(:process).with(an_instance_of(Pulljoy::PullRequestEvent))
      expect(event_handler_factory).to receive(:create).and_return(event_handler)

      body = JSON.generate(pr_open_event.to_h)
      post(
        '/receive_github_event',
        body,
        'HTTP_X_GITHUB_EVENT' => 'pull_request',
        'HTTP_X_HUB_SIGNATURE' => create_github_webhook_signature(body),
      )
      expect(last_response.status).to eq(200)
      expect(last_json_body).to eq(processed: true)
    end
  end
end
