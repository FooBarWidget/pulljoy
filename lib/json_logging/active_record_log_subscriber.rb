# frozen_string_literal: true

require 'active_record'
require 'active_support/log_subscriber'

module Pulljoy
  module JSONLogging
    # Debug prints Active Record SQL statements in JSON format.
    class ActiveRecordLogSubscriber < ActiveSupport::Subscriber
      IGNORE_PAYLOAD_NAMES = %w[SCHEMA EXPLAIN].freeze

      def initialize(logger)
        super()
        @logger = logger
      end

      def sql(event)
        return unless logger.debug?
        return if IGNORE_PAYLOAD_NAMES.include?(event.payload[:name])

        sql   = event.payload[:sql]
        binds = format_binds(event)

        logger.debug(format_title(event), query: "#{sql}#{binds}")
      end

      private

      def format_title(event)
        result = "#{event.payload[:name]} (#{event.duration.round(1)}ms)"
        result = "CACHE #{result}" if event.payload[:cached]
        result
      end

      def format_binds(event)
        return if (event.payload[:binds] || []).empty?

        casted_params = type_casted_binds(event.payload[:type_casted_binds])
        result = event.payload[:binds].zip(casted_params).map do |attr, value|
          render_bind(attr, value)
        end
        "  #{result.inspect}"
      end

      def type_casted_binds(casted_binds)
        casted_binds.respond_to?(:call) ? casted_binds.call : casted_binds
      end

      def render_bind(attr, value)
        if attr.is_a?(Array)
          attr = attr.first
        elsif attr.type.binary? && attr.value
          value = "<#{attr.value_for_database.to_s.bytesize} bytes of binary data>"
        end

        [attr&.name, value]
      end

      def logger # rubocop:disable Style/TrivialAccessors
        @logger
      end
    end
  end
end
