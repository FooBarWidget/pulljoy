# frozen_string_literal: true

source 'https://rubygems.org'

ruby '>= 2.7'

gem 'activesupport'
gem 'amazing_print' # used by Ougai.log_format == 'human'
gem 'dry-struct'
gem 'google-cloud-firestore'
gem 'octokit'
gem 'ougai'

group :google_cloud_functions, :test do
  gem 'functions_framework', '~> 0.9'
  gem 'google-cloud-pubsub'
  gem 'rack-github_webhooks'
end

group :selfhost do
  gem 'puma'
end

group :selfhost, :test do
  gem 'sinatra'
  gem 'sinatra-contrib'
  gem 'sinatra-github_webhooks'
end

group :development, :test do
  gem 'byebug'
  gem 'pry'
  gem 'rubocop'
end

group :test do
  gem 'rack-test'
  gem 'rspec'
  gem 'webmock'
end
