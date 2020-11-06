# frozen_string_literal: true

require 'dry-struct'
require_relative 'types'

module Pulljoy
  class Config < Dry::Struct
    attribute :git_auth_strategy, Types::Coercible::String.
      enum('none', 'token').default('none')
    attribute :git_auth_token, Types::Coercible::String.optional
  end
end
