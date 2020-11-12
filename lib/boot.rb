# frozen_string_literal: true

require_relative 'config'

module Pulljoy
  module Boot
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
      end

      # @param config [Config]
      # @return [Octokit::Client]
      def create_octokit(config)
        require 'octokit'

        Octokit::Client.new(access_token: config.github_access_token)
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
      end

      # @param octokit [Octokit::Client]
      # @return [String]
      def infer_github_username(octokit)
        octokit.user.login
      end

      # @param config [Config]
      def establish_db_connection(config, logger)
        require 'active_record'
        require 'composite_primary_keys'

        db_config = config.database
        ActiveRecord::Base.configurations = { 'default' => db_config }
        ActiveRecord::Base.establish_connection(db_config)
        ActiveRecord::Tasks::DatabaseTasks.database_configuration = db_config
        ActiveRecord::Tasks::DatabaseTasks.db_dir = 'db'

        case config.log_format
        when 'human'
          ActiveRecord::Base.logger = logger
        when 'json'
          require_relative 'json_logging/active_record_log_subscriber'

          log_subscriber = JSONLogging::ActiveRecordLogSubscriber.new(logger)
          JSONLogging::ActiveRecordLogSubscriber.attach_to(:active_record, log_subscriber)
        end
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
