# frozen_string_literal: true

require_relative '../lib/boot'
require_relative '../lib/puma_json_formatter'

config_source = Pulljoy::Boot.infer_config_source
if config_source.nil?
  STDERR.puts 'Please specify a config file, for example with PULLJOY_CONFIG_PATH.'
  abort
end

begin
  config = Pulljoy::Boot.load_config(config_source)
rescue Psych::SyntaxError => e
  STDERR.puts "Syntax error in config file: #{e}"
  abort
rescue Dry::Struct::Error => e
  STDERR.puts "Config file validation error: #{e}"
  abort
end

if config.log_format == 'json'
  json_formatter = Pulljoy::PumaJSONFormatter.new

  log_formatter do |msg|
    json_formatter.call(msg)
  end
end
