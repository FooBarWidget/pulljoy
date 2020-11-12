# frozen_string_literal: true

require_relative 'spec_helper'
require 'json'
require 'stringio'
require 'octokit'
require_relative '../lib/event_handler'

describe Pulljoy::EventHandler do
  before :each do
    @logio = StringIO.new
    @logger = Ougai::Logger.new(@logio)
    @logger.level = :debug
    @octokit = Octokit::Client.new(access_token: PULLJOY_TEST_CONFIG.github_access_token)
  end

  around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  let(:my_username) { 'pulljoy' }

  def create_event_handler
    Pulljoy::EventHandler.new(
      config: PULLJOY_TEST_CONFIG,
      octokit: @octokit,
      logger: @logger,
      my_username: my_username,
    )
  end

  describe 'upon opening a pull request' do
    let(:event) do
      Pulljoy::PullRequestEvent.new(
        action: Pulljoy::PullRequestEvent::ACTION_OPENED,
        repository: {
          full_name: 'test/test'
        },
        user: {
          login: 'pulljoy'
        },
        pull_request: {
          number: 123,
          head: {
            sha: 'head',
            repo: {
              full_name: 'fork/test',
            }
          },
          base: {
            sha: 'base',
            repo: {
              full_name: 'test/test'
            }
          }
        }
      )
    end

    def stub_comment_post
      stub_request(
        :post,
        "https://api.github.com/repos/#{event.repository.full_name}/issues/#{event.pull_request.number}/comments"
      ).to_return(status: 200)
    end

    it 'requests a review' do
      comment_post_req = stub_comment_post.with(body: /Please review whether it's safe to start a CI run/)
      create_event_handler.process(event)
      expect(comment_post_req).to have_been_requested
    end

    it 'transitions to the awaiting_manual_review state' do
      stub_comment_post
      create_event_handler.process(event)

      state = Pulljoy::EventHandler::State.where(
        repo: event.repository.full_name,
        pr_num: event.pull_request.number
      ).first
      expect(state.state_name).to eq(Pulljoy::EventHandler::STATE_AWAITING_MANUAL_REVIEW)
    end
  end

  describe 'upon reopening a pull request' do
    let(:event) do
      Pulljoy::PullRequestEvent.new(
        action: Pulljoy::PullRequestEvent::ACTION_REOPENED,
        repository: {
          full_name: 'test/test'
        },
        user: {
          login: 'pulljoy'
        },
        pull_request: {
          number: 123,
          head: {
            sha: 'head',
            repo: {
              full_name: 'fork/test',
            }
          },
          base: {
            sha: 'base',
            repo: {
              full_name: 'test/test'
            }
          }
        }
      )
    end

    def stub_comment_post
      stub_request(
        :post,
        "https://api.github.com/repos/#{event.repository.full_name}/issues/#{event.pull_request.number}/comments"
      ).to_return(status: 200, body: '{}')
    end

    it 'requests a review' do
      comment_post_req = stub_comment_post.with(body: /Please review whether it's safe to start a CI run/)
      create_event_handler.process(event)
      expect(comment_post_req).to have_been_requested
    end

    it 'transitions to the awaiting_manual_review state' do
      stub_comment_post
      create_event_handler.process(event)

      state = Pulljoy::EventHandler::State.where(
        repo: event.repository.full_name,
        pr_num: event.pull_request.number
      ).first
      expect(state.state_name).to eq(Pulljoy::EventHandler::STATE_AWAITING_MANUAL_REVIEW)
    end
  end

  describe 'upon closing a pull request' do
    let(:event) do
      Pulljoy::PullRequestEvent.new(
        action: Pulljoy::PullRequestEvent::ACTION_CLOSED,
        repository: {
          full_name: 'test/test'
        },
        user: {
          login: 'pulljoy'
        },
        pull_request: {
          number: 123,
          head: {
            sha: 'head',
            repo: {
              full_name: 'fork/test',
            }
          },
          base: {
            sha: 'base',
            repo: {
              full_name: 'test/test'
            }
          }
        }
      )
    end

    it 'resets the state' do
      create_event_handler.process(event)
      state = Pulljoy::EventHandler::State.where(
        repo: event.repository.full_name,
        pr_num: event.pull_request.number
      ).first
      expect(state).to be_nil
    end

    describe 'when a CI build is in progress' do
      before :each do
        Pulljoy::EventHandler::State.create!(
          repo: event.repository.full_name,
          pr_num: event.pull_request.number,
          state_name: Pulljoy::EventHandler::STATE_AWAITING_CI,
          commit_sha: local_branch_sha,
        )
      end

      let(:local_branch_sha) { 'local' }
      let(:workflow_run_id) { 1337 }

      def stub_query_runs
        stub_request(
          :get,
          "https://api.github.com/repos/#{event.repository.full_name}/actions/runs?status=queued"
        ).to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: JSON.generate(
            total_count: 1,
            workflow_runs: [
              {
                id: workflow_run_id,
                head_sha: local_branch_sha
              }
            ]
          )
        )
      end

      def stub_cancel_run
        stub_request(
          :post,
          "https://api.github.com/repos/#{event.repository.full_name}" \
            "/actions/runs/#{workflow_run_id}/cancel"
        ).to_return(status: 200)
      end

      def stub_delete_branch
        stub_request(
          :delete,
          "https://api.github.com/repos/#{event.repository.full_name}" \
            "/git/refs/heads/pulljoy/#{event.pull_request.number}"
        ).to_return(status: 200)
      end

      it 'cancels the CI build' do
        query_runs_req = stub_query_runs
        cancel_run_req = stub_cancel_run
        stub_delete_branch

        create_event_handler.process(event)
        expect(query_runs_req).to have_been_requested
        expect(cancel_run_req).to have_been_requested
      end

      it 'deletes the local branch' do
        stub_query_runs
        stub_cancel_run
        delete_branch_req = stub_delete_branch

        create_event_handler.process(event)
        expect(delete_branch_req).to have_been_requested
      end
    end
  end

  describe 'upon pushing new code' do
    let(:event) do
      Pulljoy::PullRequestEvent.new(
        action: Pulljoy::PullRequestEvent::ACTION_SYNCHRONIZE,
        repository: {
          full_name: 'test/test'
        },
        user: {
          login: 'pulljoy'
        },
        pull_request: {
          number: 123,
          head: {
            sha: 'head',
            repo: {
              full_name: 'fork/test',
            }
          },
          base: {
            sha: 'base',
            repo: {
              full_name: 'test/test'
            }
          }
        }
      )
    end

    let(:first_review_id) { 'first-review' }
    let(:local_branch_sha) { 'local' }
    let(:workflow_run_id) { 1337 }

    def initialize_with_awaiting_manual_review_state
      Pulljoy::EventHandler::State.create!(
        repo: event.repository.full_name,
        pr_num: event.pull_request.number,
        state_name: Pulljoy::EventHandler::STATE_AWAITING_MANUAL_REVIEW,
        review_id: first_review_id,
      )
    end

    def initialize_with_awaiting_ci_state
      Pulljoy::EventHandler::State.create!(
        repo: event.repository.full_name,
        pr_num: event.pull_request.number,
        state_name: Pulljoy::EventHandler::STATE_AWAITING_CI,
        commit_sha: local_branch_sha,
      )
    end

    def stub_query_runs
      stub_request(
        :get,
        "https://api.github.com/repos/#{event.repository.full_name}/actions/runs?status=queued"
      ).to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: JSON.generate(
          total_count: 1,
          workflow_runs: [
            {
              id: workflow_run_id,
              head_sha: local_branch_sha
            }
          ]
        )
      )
    end

    def stub_cancel_run
      stub_request(
        :post,
        "https://api.github.com/repos/#{event.repository.full_name}" \
          "/actions/runs/#{workflow_run_id}/cancel"
      ).to_return(status: 200)
    end

    def stub_delete_branch
      stub_request(
        :delete,
        "https://api.github.com/repos/#{event.repository.full_name}" \
          "/git/refs/heads/pulljoy/#{event.pull_request.number}"
      ).to_return(status: 200)
    end

    def stub_comment_post
      stub_request(
        :post,
        "https://api.github.com/repos/#{event.repository.full_name}/issues/#{event.pull_request.number}/comments"
      ).to_return(status: 200, body: '{}')
    end

    it 'cancels the previous CI build' do
      initialize_with_awaiting_ci_state

      query_runs_req = stub_query_runs
      cancel_run_req = stub_cancel_run
      stub_delete_branch
      stub_comment_post

      create_event_handler.process(event)
      expect(query_runs_req).to have_been_requested
      expect(cancel_run_req).to have_been_requested
    end

    it 'deletes the local branch' do
      initialize_with_awaiting_ci_state

      stub_query_runs
      stub_cancel_run
      delete_branch_req = stub_delete_branch
      stub_comment_post

      create_event_handler.process(event)
      expect(delete_branch_req).to have_been_requested
    end

    it 'requests a review' do
      initialize_with_awaiting_manual_review_state
      comment_post_req = stub_comment_post.with(body: /Please review whether it's safe to start a CI run/)

      create_event_handler.process(event)

      expect(comment_post_req).to have_been_requested
    end

    it 'transitions to the awaiting_manual_review state' do
      initialize_with_awaiting_manual_review_state
      stub_comment_post

      create_event_handler.process(event)

      state = Pulljoy::EventHandler::State.where(
        repo: event.repository.full_name,
        pr_num: event.pull_request.number
      ).first
      expect(state.state_name).to eq(Pulljoy::EventHandler::STATE_AWAITING_MANUAL_REVIEW)
    end

    it 'changes the review ID' do
      initialize_with_awaiting_manual_review_state
      stub_comment_post

      create_event_handler.process(event)

      state = Pulljoy::EventHandler::State.where(
        repo: event.repository.full_name,
        pr_num: event.pull_request.number
      ).first
      expect(state.review_id).not_to eq(first_review_id)
    end
  end

  describe 'upon responding to a review request' do
    describe 'when the wrong review ID is given' do
      it 'tells the sender that the ID is wrong'
    end
    describe 'when the right review ID is given' do
      it 'creates a local branch'
    end
    describe 'when the sender does not have write access to the repo' do
      it 'ignores the response'
    end
  end

  describe 'upon CI run completion' do
    describe 'if the run is not for the latest pushed commit'
    describe 'if the run is not for a repo we know about'
    describe 'if the run is not for a PR for which we have state'
    describe 'if not all check suites for the commit are completed'
    describe 'if we are in the awaiting_manual_review state' do
      it 'ignores the event'
    end
    describe 'if we are in the standing_by state' do
      it 're-reports the result'
    end
    describe 'if we are in the awaiting_ci state' do
      it 'reports the result'
    end
  end

  describe 'when deleting a local branch' do
    it 'does nothing when the branch does not exist'
    it 'raises the API error if the error is not related to the branch not existing'
  end

  describe 'when canceling a CI run' do
    it 'finds the run in the run in queued workflow runs'
    it 'finds the run in the run in in-progress workflow runs'
    it 'does nothing when there is no CI run'
  end
end
