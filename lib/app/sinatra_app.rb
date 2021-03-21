# frozen_string_literal: true

require 'sinatra'
require 'sinatra/json'
require 'sinatra/github_webhooks'
require_relative '../event_handler'
require_relative '../github_api_types'

module Pulljoy
  module App
    class SinatraApp < Sinatra::Base
      def self.activate_pulljoy_config(config)
        set :pulljoy_config, config
        set :github_webhook_secret, config.github_webhook_secret
      end

      def initialize(options)
        super()
        @event_handler_factory = read_option(options, :event_handler_factory)
        @logger_template = read_option(options, :logger)
        @state_store = read_option(options, :state_store)
      end

      configure do
        set :dump_errors, false
      end

      helpers Sinatra::GithubWebhooks

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
        @state_store.release_thread_local_connection
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

      post '/receive_github_event' do
        @logger.info("Github event type: #{github_event.inspect}")

        return json(processed: true) if github_event == 'ping'

        event = Pulljoy.parse_github_event_data(github_event, payload)

        if event
          event_handler = @event_handler_factory.create
          event_handler.process(event)
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
end
