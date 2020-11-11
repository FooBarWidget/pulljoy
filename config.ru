# frozen_string_literal: true

require './lib/boot'
require './lib/app'

config_source = Pulljoy::Boot.infer_config_source!
config = Pulljoy::Boot.load_config!(config_source)
logger = Pulljoy::Boot.create_logger(config)
octokit = Pulljoy::Boot.create_octokit(config)

Pulljoy::App.set :environment, ENV['RACK_ENV']
Pulljoy::App.activate_pulljoy_config(config)
Pulljoy::Boot.establish_db_connection(config, logger)

run Pulljoy::App.new(
  my_github_username: Pulljoy::Boot.infer_github_username(octokit),
  octokit: octokit,
  logger: logger,
)
