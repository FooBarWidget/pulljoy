# frozen_string_literal: true

require 'bundler/setup'

namespace :db do
  task :_boot do
    require_relative 'lib/boot'

    config_source = Pulljoy::Boot.infer_config_source!
    config = Pulljoy::Boot.load_config!(config_source)
    logger = Pulljoy::Boot.create_logger(config)
    Pulljoy::Boot.establish_db_connection(config, logger)
  end

  desc 'Migrate the db'
  task migrate: :_boot do
    ActiveRecord::Tasks::DatabaseTasks.migrate
    Rake::Task['db:schema:dump'].invoke
  end

  desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n)'
  task rollback: :_boot do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    ActiveRecord::Base.connection.migration_context.rollback(step)
    Rake::Task['db:schema:dump'].invoke
  end

  namespace :schema do
    desc 'Creates a db/schema.rb file that is portable against any DB supported by Active Record'
    task dump: :_boot do
      require 'active_record/schema_dumper'

      File.open('db/schema.rb', 'w:utf-8') do |file|
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
      end
      Rake::Task['db:schema:dump'].reenable
    end

    desc 'Loads a schema.rb file into the database'
    task load: :_boot do
      ActiveRecord::Tasks::DatabaseTasks.load_schema_current(:ruby, nil, 'default')
    end
  end
end
