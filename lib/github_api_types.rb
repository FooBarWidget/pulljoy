# frozen_string_literal: true

require 'dry-struct'
require_relative 'utils'

module Pulljoy
  class Repository < Dry::Struct
    transform_keys(&:to_sym)

    attribute :full_name, Types::Strict::String
  end

  class User < Dry::Struct
    transform_keys(&:to_sym)

    attribute :login, Types::Strict::String
  end

  class PullRequestRepositoryReference < Dry::Struct
    transform_keys(&:to_sym)

    attribute :sha, Types::Strict::String
    attribute :repo, Repository
  end

  class PullRequest < Dry::Struct
    transform_keys(&:to_sym)

    attribute :number, Types::Strict::Integer
    attribute :head, PullRequestRepositoryReference
    attribute :base, PullRequestRepositoryReference
  end

  class PullRequestEvent < Dry::Struct
    ACTION_OPENED = 'opened'
    ACTION_CLOSED = 'closed'
    ACTION_SYNCHRONIZE = 'synchronize'
    ACTION_REOPENED = 'reopened'

    transform_keys(&:to_sym)

    attribute :action, Types::Strict::String
    attribute :repository, Repository
    attribute :user, User
    attribute :pull_request, PullRequest
  end

  class IssueCommentEvent < Dry::Struct
    # Possible values for 'action'
    ACTION_CREATED = 'created'

    transform_keys(&:to_sym)

    attribute :action, Types::Strict::String
    attribute :repository, Repository
    attribute :issue do
      attribute :number, Types::Strict::Integer
    end
    attribute :comment do
      attribute :id, Types::Strict::Integer
      attribute :body, Types::Strict::String
      attribute :user, User
    end
  end

  class CheckSuiteEvent < Dry::Struct
    ACTION_COMPLETED = 'completed'
    STATUS_COMPLETED = 'completed'
    STATUS_QUEUED    = 'queued'
    CONCLUSION_SUCCESS = 'success'

    transform_keys(&:to_sym)

    attribute :action, Types::Strict::String
    attribute :repository, Repository
    attribute :check_suite do
      attribute :head_sha, Types::Strict::String
      attribute :status, Types::Strict::String
      attribute? :conclusion, Types::Strict::String.optional
      attribute :pull_requests, Types::Strict::Array do
        attribute :number, Types::Strict::Integer
      end
    end
  end
end
