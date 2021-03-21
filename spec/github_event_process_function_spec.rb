# frozen_string_literal: true

require_relative 'spec_helper'
require 'base64'
require 'json'
require 'ougai'
require 'octokit'
require_relative '../lib/github_api_types'
require_relative '../lib/state_store/memory_store'
require_relative '../lib/app/gcloud_functions/github_event_process_function'

describe 'GCloud Function github_event_process' do
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

  let(:octokit) { Octokit::Client.new(access_token: PULLJOY_TEST_CONFIG.github_access_token) }
  let(:state_store) { Pulljoy::StateStore::MemoryStore.new }

  # @param github_event_type [String]
  # @param github_event [PullRequest::GithubEvent]
  def create_function_object(github_event_type, github_event)
    event = double(
      'Event',
      data: {
        'message' => {
          'data' => Base64.strict_encode64(JSON.generate(github_event.to_h)),
          'attributes' => {
            'github_event_type' => github_event_type,
          },
        },
      },
    )
    Pulljoy::App::GCloudFunctions::GithubEventProcessFunction.new(
      event: event,
      config: PULLJOY_TEST_CONFIG,
      octokit: octokit,
      logger: logger,
      my_username: 'foo',
      state_store: state_store,
    )
  end

  it 'passes the event to the event handler' do
    func = create_function_object('pull_request', pr_open_event)

    expect(func).to receive(:create_event_handler).and_wrap_original do |m, *args|
      event_handler = m.call(*args)
      expect(event_handler).to receive(:process).with(pr_open_event)
      event_handler
    end

    func.process
  end
end
