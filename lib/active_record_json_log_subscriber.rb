# frozen_string_literal: true

require 'active_record'
require 'active_support/log_subscriber'

module Pulljoy
  # Debug prints Active Record SQL statements in JSON format.
  class ActiveRecordJSONLogSubscriber < ActiveSupport::Subscriber
    IGNORE_PAYLOAD_NAMES = %w(SCHEMA EXPLAIN)

    def initialize(logger)
      super()
      @logger = logger
    end

    def sql(event)
      return unless logger.debug?

      payload = event.payload

      return if IGNORE_PAYLOAD_NAMES.include?(payload[:name])

      name  = "#{payload[:name]} (#{event.duration.round(1)}ms)"
      name  = "CACHE #{name}" if payload[:cached]
      sql   = payload[:sql]
      binds = nil

      unless (payload[:binds] || []).empty?
        casted_params = type_casted_binds(payload[:type_casted_binds])
        binds = "  " + payload[:binds].zip(casted_params).map { |attr, value|
          render_bind(attr, value)
        }.inspect
      end

      logger.debug(name, query: "#{sql}#{binds}")
    end

    private

    def type_casted_binds(casted_binds)
      casted_binds.respond_to?(:call) ? casted_binds.call : casted_binds
    end

    def render_bind(attr, value)
      if attr.is_a?(Array)
        attr = attr.first
      elsif attr.type.binary? && attr.value
        value = "<#{attr.value_for_database.to_s.bytesize} bytes of binary data>"
      end

      [attr && attr.name, value]
    end

    def logger
      @logger
    end
  end
end
