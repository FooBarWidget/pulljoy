# frozen_string_literal: true

require 'dry-struct'
require_relative 'state_store/google_fire_store_config'
require_relative 'utils'

module Pulljoy
  class Config < Dry::Struct
    transform_keys(&:to_sym)

    attribute? :log_format, Types::Coercible::String
      .default('human')
      .enum('json', 'human')
    attribute? :log_level, Types::Coercible::String
      .default('info')
      .enum('fatal', 'error', 'warn', 'info', 'debug')

    attribute? :git_auth_strategy, Types::Coercible::String
      .default('none')
      .enum('none', 'token')
    attribute? :git_auth_token, Types::Coercible::String.optional

    attribute :github_access_token, Types::Coercible::String
    attribute :github_webhook_secret, Types::Coercible::String

    attribute :state_store_type, Types::Coercible::String
      .enum('google_fire_store', 'memory')
    attribute? :state_store_config,
               StateStore::GoogleFireStoreConfig |
               Types::Strict::Nil
  end
end
