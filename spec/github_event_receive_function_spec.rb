# frozen_string_literal: true

require_relative 'spec_helper'
require 'json'
require 'ougai'
require 'functions_framework/testing'
require 'active_support/core_ext/hash/keys'
require_relative 'github_webhook_helper'
require_relative '../lib/github_api_types'
require_relative '../lib/app/gcloud_functions/github_event_receive_function'

describe 'GCloud Function github_event_receive' do
  include FunctionsFramework::Testing

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

  let(:logger) do
    logger = Ougai::Logger.new($stderr)
    logger.level = :fatal
    logger
  end

  # @param req [Rack::Request]
  def create_function_object(req, topic)
    Pulljoy::App::GCloudFunctions::GithubEventReceiveFunction.new(
      req: req,
      config: PULLJOY_TEST_CONFIG,
      logger: logger,
      topic: topic,
    )
  end

  # @param rack_body [Array<String>]
  # @return [Hash]
  def body_as_json(rack_body)
    JSON.parse(rack_body.join).deep_symbolize_keys
  end

  it 'responds to pings' do
    req = make_post_request(
      '/',
      '{}',
      'X-Github-Event' => 'ping',
      'X-Hub-Signature' => create_github_webhook_signature('{}'),
    )
    status, _, body = create_function_object(req, nil).process
    expect(status).to eq(200)
    expect(body_as_json(body)).to eq(processed: true)
  end

  it 'errors upon receiving an unsupported event type' do
    req = make_post_request(
      '/',
      '{}',
      'X-Github-Event' => 'foo',
      'X-Hub-Signature' => create_github_webhook_signature('{}'),
    )
    status, _, body = create_function_object(req, nil).process
    expect(status).to eq(422)
    expect(body_as_json(body)).to eq(
      processed: false,
      message: 'Unsupported event type "foo"',
    )
  end

  it 'accepts a supported event type' do
    body = JSON.generate(pr_open_event.to_h)
    req = make_post_request(
      '/receive_github_event',
      body,
      'X-Github-Event' => 'pull_request',
      'X-Hub-Signature' => create_github_webhook_signature(body),
    )

    topic = double('Topic')
    expect(topic).to receive(:publish).with(
      body,
      github_event_type: 'pull_request',
    )

    func = create_function_object(req, topic)
    status, _, body = func.process

    expect(status).to eq(200)
    expect(body_as_json(body)).to eq(processed: true)
  end
end
