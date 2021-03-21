# frozen_string_literal: true

require_relative 'gcloud_config'
require_relative 'utils'

module Pulljoy
  class GCloudPubSubConfig < GCloudConfig
    attribute :topic_name, Types::Coercible::String
  end
end
