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

  class GithubEvent < Dry::Struct
    transform_keys(&:to_sym)
  end

  class PullRequestEvent < GithubEvent
    ACTION_OPENED = 'opened'
    ACTION_CLOSED = 'closed'
    ACTION_SYNCHRONIZE = 'synchronize'
    ACTION_REOPENED = 'reopened'

    attribute :action, Types::Strict::String
    attribute :repository, Repository
    attribute :user, User
    attribute :pull_request, PullRequest
  end

  class IssueCommentEvent < GithubEvent
    # Possible values for 'action'
    ACTION_CREATED = 'created'

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

  class CheckSuiteEvent < GithubEvent
    ACTION_COMPLETED = 'completed'
    STATUS_COMPLETED = 'completed'
    STATUS_QUEUED    = 'queued'
    CONCLUSION_SUCCESS = 'success'

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


  # @param event_type [String]
  # @param doc [Hash]
  # @return [GithubEvent, nil]
  def self.parse_github_event_data(event_type, doc)
    case event_type
    when 'pull_request'
      PullRequestEvent.new(doc)
    when 'issue_comment'
      IssueCommentEvent.new(doc)
    when 'check_suite'
      CheckSuiteEvent.new(doc)
    end
  end
end
