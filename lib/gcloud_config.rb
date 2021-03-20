# frozen_string_literal: true

require 'dry-struct'
require_relative 'utils'

module Pulljoy
  class GCloudConfig < Dry::Struct
    transform_keys(&:to_sym)

    attribute? :project_id, Types::Coercible::String.optional
    attribute? :credentials,
               Types::Coercible::String |
               Types::Coercible::Hash |
               Types::Strict::Nil
    attribute? :scope,
               Types::Coercible::String |
               Types::Coercible::Array.of(Types::Coercible::String) |
               Types::Strict::Nil
    attribute? :timeout, Types::Coercible::Integer.optional
    attribute? :endpoint, Types::Coercible::String.optional
    attribute? :emulator_host, Types::Coercible::String.optional
  end
end
