# frozen_string_literal: true

require 'yaml'
require 'rspec'
require 'webmock/rspec'
require_relative '../lib/boot'

PULLJOY_TEST_CONFIG = Pulljoy::Config.new(
  github_access_token: '1234',
  github_webhook_secret: '5678',
  state_store_type: 'memory',
)
PULLJOY_TEST_LOGGER = Pulljoy::Boot.create_logger(PULLJOY_TEST_CONFIG)
