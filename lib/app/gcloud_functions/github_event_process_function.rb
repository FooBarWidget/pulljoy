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
          @@my_username = Boot.infer_github_username(@@octokit)
          @@state_store = Boot.create_state_store(@@config)
        end

        FunctionsFramework.cloud_event 'pulljoy_github_event_process' do |event|
          function_object = GithubEventProcessFunction.new(
            event: event,
            config: @@config,
            octokit: @@octokit,
            logger: logger,
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
          payload = JSON.parse(@event.data)
          payload_data_json = Base64.strict_decode64(payload['message']['data'])
          payload_data_doc = JSON.parse(payload_data_json)

          github_event = Pulljoy.parse_github_event_data(
            payload['attributes']['github_event_type'],
            payload_data_doc
          )
          handler = create_event_handler
          handler.process(github_event)
        end

        private

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
