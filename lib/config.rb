# frozen_string_literal: true

require 'dry-struct'
require_relative 'types'

module Pulljoy
  class Config < Dry::Struct
    transform_keys(&:to_sym)

    attribute? :log_format, Types::Coercible::String.
      default('json').
      enum('json', 'human')
    attribute? :log_level, Types::Coercible::String.
      default('info').
      enum('fatal', 'error', 'warn', 'info', 'debug')

    attribute? :git_auth_strategy, Types::Coercible::String.
      default('none').
      enum('none', 'token')
    attribute? :git_auth_token, Types::Coercible::String.optional

    attribute :github_access_token, Types::Coercible::String
    attribute :github_webhook_secret, Types::Coercible::String
  end
end
