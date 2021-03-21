# frozen_string_literal: true

require 'functions_framework'
require 'json'
require 'base64'
require_relative '../../boot'
require_relative '../../github_api_types'
require_relative '../../event_handler'

module Pulljoy
  module App
    module GCloudFunctions
      class GithubEventProcessFunction
        FunctionsFramework.on_startup do
          config_source = Boot.infer_config_source!
          @@config      = Boot.load_config!(config_source)
          @@octokit     = Boot.create_octokit(@@config)
          @@logger      = Boot.create_logger(@@config)
          @@my_username = Boot.infer_github_username(@@octokit)
          @@state_store = Boot.create_state_store(@@config)
        end

        FunctionsFramework.cloud_event 'pulljoy_github_event_process' do |event|
          function_object = GithubEventProcessFunction.new(
            event: event,
            config: @@config,
            octokit: @@octokit,
            logger: @@logger,
            my_username: @@my_username,
            state_store: @@state_store,
          )
          function_object.process
        end


        # @param config [Pulljoy::Config]
        # @param octokit [Octokit::Client]
        # @param my_username [String]
        # @param state_store [Pulljoy::StateStore::Base]
        def initialize(event:, config:, octokit:, logger:, my_username:, state_store:) # rubocop:disable Metrics/ParameterLists
          @event       = event
          @config      = config
          @octokit     = octokit
          @logger      = logger
          @my_username = my_username
          @state_store = state_store
        end

        def process
          message_data, attributes = extract_event_info
          @logger.info("Github event type: #{attributes['github_event_type'].inspect}")

          github_event = Pulljoy.parse_github_event_data(
            attributes['github_event_type'],
            message_data
          )
          create_event_handler.process(github_event)
        end

        private

        # @return [Array<(Hash, Hash)>]
        def extract_event_info
          payload = JSON.parse(@event.data)
          message_data_raw = Base64.strict_decode64(payload['message']['data'])
          message_data = JSON.parse(message_data_raw)
          attributes = payload['attributes']
          [message_data, attributes]
        end

        # @return [Pulljoy::EventHandler]
        def create_event_handler
          EventHandler.new(
            config: @config,
            octokit: @octokit,
            logger: @logger,
            my_username: @my_username,
            state_store: @state_store,
          )
        end
      end
    end
  end
end
