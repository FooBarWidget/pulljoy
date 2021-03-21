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
          GithubEventReceiveFunction.new(req: req, config: @@config, topic: @@topic).process
        end


        # @param req [Rack::Request]
        # @param config [Pulljoy::Config]
        # @param topic [Google::Cloud::PubSub::Topic]
        def initialize(req:, config:, topic:)
          @req = req
          @config = config
          @topic = topic
        end

        # @return [Array]
        def process
          event_type = @req.get_header('HTTP_X_GITHUB_EVENT')
          body = @req.body.read
          body_doc = JSON.parse(body)

          return [400, {}, ["Wrong Github signature!\n"]] if !verify_github_webhooks_signature(body)

          return json_response(200, processed: true) if event_type == 'ping'

          event = Pulljoy.parse_github_event_data(event_type, body_doc)
          if event.nil?
            return json_response(
              422,
              processed: false,
              message: "Unsupported event type #{event_type.inspect}",
            )
          end

          @topic.publish_async(
            body,
            { github_event_type: event_type },
            ordering_key: event.ordering_key,
          )
          @topic.async_publisher.stop!
          json_response(200, processed: true)
        end

        private

        # @param body [String]
        # @return [Boolean]
        def verify_github_webhooks_signature(body)
          signature = Rack::GithubWebhooks::Signature.new(
            @config.github_webhook_secret,
            @req.get_header('HTTP_X_HUB_SIGNATURE'),
            body,
          )
          signature.valid?
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
