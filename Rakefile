# frozen_string_literal: true

require 'bundler/setup'

namespace :db do
  task :_boot do
    require_relative 'lib/boot'
    require 'active_record'

    config_source = Pulljoy::Boot.infer_config_source!
    config = Pulljoy::Boot.load_config!(config_source)
    logger = Pulljoy::Boot.create_logger(config)
    Pulljoy::Boot.establish_db_connection(config, logger)
  end

  desc 'Migrate the db'
  task migrate: :_boot do
    ActiveRecord::Tasks::DatabaseTasks.migrate
  end

  desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n)'
  task rollback: :_boot do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    ActiveRecord::Base.connection.migration_context.rollback(step)
  end
end
