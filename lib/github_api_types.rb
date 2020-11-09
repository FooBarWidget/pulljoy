# frozen_string_literal: true

require 'dry-struct'
require_relative 'types'

module Pulljoy
  class Repository < Dry::Struct
    attribute :full_name, Types::Strict::String
  end

  class User < Dry::Struct
    attribute :login, Types::Strict::String
  end

  class PullRequestRepositoryReference < Dry::Struct
    attribute :sha, Types::Strict::String
    attribute :repo, Repository
  end

  class PullRequest < Dry::Struct
    attribute :node_id, Types::Strict::String
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
    attribute :number, Types::Strict::Integer
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
      attribute :node_id, Types::Strict::String
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

    transform_keys(&:to_sym)

    attribute :action, Types::Strict::String
    attribute :repository, Repository
    attribute :check_suite do
      attribute :node_id, Types::Strict::String
      attribute :head_sha, Types::Strict::String
      attribute :conclusion, Types::Strict::String
      attribute :pull_requests, Types::Array.of(PullRequest)
    end
  end
end
