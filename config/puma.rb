# frozen_string_literal: true

require_relative '../lib/boot'
require_relative '../lib/json_logging/puma_formatter'

config_source = Pulljoy::Boot.infer_config_source!
config = Pulljoy::Boot.load_config!(config_source)

if config.log_format == 'json'
  json_formatter = Pulljoy::JSONLogging::PumaFormatter.new

  log_formatter do |msg|
    json_formatter.call(msg)
  end
end
