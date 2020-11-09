# frozen_string_literal: true

require './lib/boot'
require './lib/app'

config_source = Pulljoy::Boot.infer_config_source
if config_source.nil?
  STDERR.puts 'Please specify a config file, for example with PULLJOY_CONFIG_PATH.'
  abort
end

begin
  config = Pulljoy::Boot.load_config(config_source)
  Pulljoy::App.activate_pulljoy_config(config)
rescue Psych::SyntaxError => e
  STDERR.puts "Syntax error in config file: #{e}"
  abort
rescue Dry::Struct::Error => e
  STDERR.puts "Config file validation error: #{e}"
  abort
end

Pulljoy::App.set :environment, ENV['RACK_ENV']
octokit = Pulljoy::Boot.create_octokit(config)

run Pulljoy::App.new(
  my_github_username: Pulljoy::Boot.infer_github_username(octokit),
  octokit: octokit,
  logger: Pulljoy::Boot.create_logger(config),
)
