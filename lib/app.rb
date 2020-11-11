# frozen_string_literal: true

require 'json'
require 'active_record'
require 'sinatra'
require 'sinatra/json'
require 'sinatra/github_webhooks'
require_relative 'event_handler'
require_relative 'github_api_types'

module Pulljoy
  class App < Sinatra::Base
    def self.activate_pulljoy_config(config)
      set :pulljoy_config, config
      set :github_webhook_secret, config.github_webhook_secret
    end

    def initialize(options)
      super()
      @my_github_username = read_option(options, :my_github_username)
      @octokit = read_option(options, :octokit)
      @logger_template = read_option(options, :logger)
    end

    configure do
      set :dump_errors, false
    end

    helpers Sinatra::GithubWebhooks

    helpers do
      def create_event_handler
        EventHandler.new(
          config: settings.pulljoy_config,
          octokit: @octokit,
          logger: @logger,
          my_username: @my_github_username,
        )
      end
    end

    before do
      @logger = @logger_template.child(
        request_id: SecureRandom.hex(8),
      )
      @logger.info(
        'Request started',
        method: request.request_method,
        path: request.path,
        ip: request.ip,
      )
    end

    after do
      @logger.info(
        'Request complete',
        status: response.status
      )
      ActiveRecord::Base.clear_active_connections!
    end

    error do
      if @logger
        e = env['sinatra.error']
        @logger.error(
          'Encountered unexpected error',
          err: {
            name: e.class.to_s,
            message: e.to_s,
            stack: Pulljoy.format_error_and_backtrace(e),
          }
        )
      end
      "Internal server error\n"
    end

    get '/ping' do
      'pong'
    end

    post '/process' do
      @logger.info("Github event type: #{github_event}")

      case github_event
      when 'pull_request'
        event = PullRequestEvent(payload)
      when 'issue_comment'
        event = IssueCommentEvent.new(payload)
      when 'check_suite'
        event = CheckSuiteEvent.new(payload)
      when 'ping'
        return json(processed: true)
      end

      if event
        create_event_handler.process(event)
        json(processed: true)
      else
        @logger.error "Unsupported event type #{github_event.inspect}"
        status 422
        json(
          processed: false,
          message: "Unsupported event type #{github_event.inspect}",
        )
      end
    end

    private

    def read_option(options, key)
      options[key] || raise(ArgumentError, "Option #{key.inspect} required")
    end
  end
end
