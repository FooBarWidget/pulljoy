# frozen_string_literal: true

require 'functions_framework'
require 'rack/github_webhooks'
require 'json'
require_relative '../../boot'
require_relative '../../github_api_types'

module Pulljoy
  module App
    module GCloudFunctions
      class GithubEventReceiveFunction
        FunctionsFramework.on_startup do
          config_source = Boot.infer_config_source!
          @@config = Boot.load_config!(config_source)
          @@logger = Boot.create_logger(@@config)
          @@topic = Boot.create_gcloud_pubsub_topic(
            @@config,
            async_options: {
              threads: {
                publish: 1,
                callback: 1,
              },
            },
          )
        end

        # @param req [Rack::Request]
        FunctionsFramework.http('pulljoy_github_event_receive') do |req|
          GithubEventReceiveFunction.new(
            req: req,
            config: @@config,
            logger: @@logger,
            topic: @@topic
          ).process
        end


        # @param req [Rack::Request]
        # @param config [Pulljoy::Config]
        # @param topic [Google::Cloud::PubSub::Topic]
        def initialize(req:, config:, logger:, topic:)
          @req = req
          @config = config
          @logger = logger
          @topic = topic
        end

        # @return [Array]
        def process
          initialize_params

          resp = verify_github_webhooks_signature
          return resp if resp

          return json_response(200, processed: true) if @event_type == 'ping'

          resp = parse_github_event_data
          return resp if resp

          push_event_into_queue
          json_response(200, processed: true)
        end

        private

        def initialize_params
          @event_type = @req.get_header('HTTP_X_GITHUB_EVENT')
          @logger.info("Github event type: #{@event_type.inspect}")

          @body = @req.body.read
          @body_doc = JSON.parse(@body)
        end

        # @return [Array, nil]
        def verify_github_webhooks_signature
          signature = Rack::GithubWebhooks::Signature.new(
            @config.github_webhook_secret,
            @req.get_header('HTTP_X_HUB_SIGNATURE'),
            @body,
          )
          return if signature.valid?

          @logger.error('Wrong Github signature')
          json_response(
            400,
            processed: false,
            message: 'Wrong Github signature'
          )
        end

        # @return [Array, nil]
        def parse_github_event_data
          @event = Pulljoy.parse_github_event_data(@event_type, @body_doc)
          return if !@event.nil?

          @logger.error("Unsupported event type #{@event_type.inspect}")
          json_response(
            422,
            processed: false,
            message: "Unsupported event type #{@event_type.inspect}",
          )
        end

        # @return [Array]
        def push_event_into_queue
          @topic.publish(
            @body,
            { github_event_type: @event_type },
          )
          @logger.info('Pushed event into queue')
          json_response(200, processed: true)
        end

        # @param code [Integer]
        # @param doc [Hash]
        # @return [Array]
        def json_response(code, doc)
          [code, { 'Content-Type' => 'application/json' }, [JSON.generate(doc)]]
        end
      end
    end
  end
end
