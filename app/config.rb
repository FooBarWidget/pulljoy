# frozen_string_literal: true

require 'dry-struct'
require_relative 'types'

module Pulljoy
  class Config < Dry::Struct
    attribute :log_format, Types::Coercible::String.
      enum('json', 'human').
      default('json')
    attribute :log_level, Types::Coercible::String.
      enum('fatal', 'error', 'warn', 'info', 'debug').
      default('info')

    attribute :git_auth_strategy, Types::Coercible::String.
      enum('none', 'token').
      default('none')
    attribute :git_auth_token, Types::Coercible::String.optional
  end
end
