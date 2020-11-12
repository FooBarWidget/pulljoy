# frozen_string_literal: true

require 'yaml'
require 'rspec'
require 'webmock/rspec'
require_relative '../lib/boot'
require 'database_cleaner/active_record'

# Load test database configuration
PULLJOY_ROOT = File.dirname(File.absolute_path(File.dirname(__FILE__)))
PULLJOY_TEST_DB_CONFIG_FILE = File.join(PULLJOY_ROOT, 'config', 'test-database-config.yml')
abort "Please create the config file #{PULLJOY_TEST_DB_CONFIG_FILE}" if !File.exist?(PULLJOY_TEST_DB_CONFIG_FILE)
PULLJOY_TEST_DB_CONFIG = YAML.load_file(PULLJOY_TEST_DB_CONFIG_FILE)

# Create test configuration objects
PULLJOY_TEST_CONFIG = Pulljoy::Config.new(
  github_access_token: '1234',
  github_webhook_secret: '5678',
  database: PULLJOY_TEST_DB_CONFIG,
)
PULLJOY_TEST_LOGGER = Pulljoy::Boot.create_logger(PULLJOY_TEST_CONFIG)


RSpec.configure do |config|
  config.before(:suite) do
    # Connect to test database
    Pulljoy::Boot.establish_db_connection(PULLJOY_TEST_CONFIG, PULLJOY_TEST_LOGGER)

    # Clear test database
    ActiveRecord::Tasks::DatabaseTasks.purge(PULLJOY_TEST_DB_CONFIG)
    begin
      ActiveRecord::Schema.verbose = false
      ActiveRecord::Tasks::DatabaseTasks.load_schema(PULLJOY_TEST_DB_CONFIG, :ruby, nil, 'test')
    ensure
      ActiveRecord::Schema.verbose = true
      ActiveRecord::Base.establish_connection(PULLJOY_TEST_DB_CONFIG)
    end

    DatabaseCleaner.strategy = :transaction
  end
end
