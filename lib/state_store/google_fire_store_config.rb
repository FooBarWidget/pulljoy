# frozen_string_literal: true

require 'dry-struct'
require_relative '../gcloud_config'
require_relative '../utils'

module Pulljoy
  module StateStore
    class GoogleFireStoreConfig < GCloudConfig
      attribute :collection_name, Types::Coercible::String
    end
  end
end
