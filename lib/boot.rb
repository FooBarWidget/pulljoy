# frozen_string_literal: true

require_relative 'config'
require_relative 'utils'

module Pulljoy
  module Boot # rubocop:disable Metrics/ModuleLength
    class << self
      def infer_config_source
        if (path = read_env_str('PULLJOY_CONFIG_PATH'))
          [:path, path]
        elsif (data = read_env_str('PULLJOY_CONFIG'))
          [:data, data]
        end
      end

      def infer_config_source!
        config_source = infer_config_source
        if config_source.nil?
          $stderr.puts 'Please specify a config file, for example with PULLJOY_CONFIG_PATH.'
          abort
        else
          config_source
        end
      end

      # @return [Config]
      # @raises [Psych::SyntaxError] Configuration syntax error
      # @raises [Dry::Struct::Error] Configuration validation error
      def load_config(config_source)
        require 'yaml'

        type, path_or_data = config_source
        case type
        when :path
          doc = File.open(path_or_data, 'r:utf-8') do |f|
            YAML.safe_load(f.read, [], [], false, path_or_data)
          end
        when :data
          doc = YAML.safe_load(path_or_data)
        else
          raise ArgumentError, "Unsupported config source type #{type.inspect}"
        end

        Config.new(doc)
      end

      def load_config!(config_source)
        load_config(config_source)
      rescue Psych::SyntaxError => e
        $stderr.puts "Syntax error in config file: #{e}"
        abort
      rescue Dry::Struct::Error => e
        $stderr.puts "Config file validation error: #{e}"
        abort
      rescue => e # rubocop:disable Style/RescueStandardError
        Pulljoy.abort_with_exception('Error loading configuration', e)
      end

      # @param config [Config]
      # @return [Octokit::Client]
      def create_octokit(config)
        require 'octokit'

        Octokit::Client.new(access_token: config.github_access_token)
      rescue => e # rubocop:disable Style/RescueStandardError
        Pulljoy.abort_with_exception('Error initializing Octokit', e)
      end

      # @param config [Config]
      # @return [Ougai::Logger]
      def create_logger(config)
        require 'ougai'

        logger = Ougai::Logger.new($stdout, progname: 'pulljoy')
        logger.level = config.log_level
        if config.log_format == 'human'
          require 'amazing_print'
          logger.formatter = Ougai::Formatters::Readable.new
        end
        logger
      rescue => e # rubocop:disable Style/RescueStandardError
        Pulljoy.abort_with_exception('Error initializing logger', e)
      end

      # @param octokit [Octokit::Client]
      # @return [String]
      def infer_github_username(octokit)
        octokit.user.login
      end

      # @param config [Config]
      def create_state_store(config)
        case config.state_store_type
        when 'google_fire_store'
          require_relative 'state_store/google_fire_store'
          require_relative 'state_store/google_fire_store_config'
          if !config.state_store_config.is_a?(StateStore::GoogleFireStoreConfig)
            abort 'Configuration error: state_store_config must be a valid Google FireStore configuration block'
          end
          StateStore::GoogleFireStore.new(config.state_store_config)
        when 'memory'
          require_relative 'state_store/memory_store'
          StateStore::MemoryStore.new
        end
      rescue => e # rubocop:disable Style/RescueStandardError
        Pulljoy.abort_with_exception('Error initializing state store', e)
      end

      # @param config [Config]
      # @return [Google::Cloud::PubSub::Topic]
      def create_gcloud_pubsub_topic(config, async_options: nil)
        abort 'Configuration error: gcloud_pubsub must be set' if config.gcloud_pubsub.nil?

        require 'google/cloud/pubsub'
        topic_name  = config.gcloud_pubsub.topic_name
        config_hash = config.gcloud_pubsub.to_h.dup
        config_hash.delete(:topic_name)
        pubsub = Google::Cloud::PubSub.new(**config_hash)
        topic = pubsub.topic(topic_name, async: async_options)
        topic.enable_message_ordering!
        topic
      rescue => e # rubocop:disable Style/RescueStandardError
        Pulljoy.abort_with_exception('Error initializing Google Cloud PubSub support', e)
      end

      private

      def read_env_str(name)
        value = ENV[name].to_s
        if value.empty?
          nil
        else
          value
        end
      end
    end
  end
end
