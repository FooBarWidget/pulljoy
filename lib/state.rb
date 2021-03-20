# frozen_string_literal: true

require 'dry-struct'
require 'active_support/core_ext/object/blank'
require_relative 'utils'

module Pulljoy
  class State < Dry::Struct
    transform_keys(&:to_sym)

    AWAITING_MANUAL_REVIEW = 'awaiting_manual_review'
    AWAITING_CI = 'awaiting_ci'
    STANDING_BY = 'standing_by'

    attribute :repo_full_name, Types::Strict::String
    attribute :pr_num, Types::Strict::Integer
    attribute :state_name, Types::Strict::String
      .enum(AWAITING_MANUAL_REVIEW, AWAITING_CI, STANDING_BY)
    attribute? :review_id, Types::Strict::String.optional
    attribute? :commit_sha, Types::Strict::String.optional

    def validate!
      if state_name == AWAITING_MANUAL_REVIEW
        assert('review_id must be present') do
          review_id.present?
        end
      else
        assert('review_id must be absent') do
          review_id.nil?
        end
      end

      if state_name == AWAITING_CI || state_name == STANDING_BY
        assert('commit_sha must be present') do
          commit_sha.present?
        end
      else
        assert('commit_sha must be absent') do
          commit_sha.nil?
        end
      end
    end

    def deep_copy
      Marshal.load(Marshal.dump(self))
    end

    private

    def assert(message)
      raise StateValidationError, message if !yield
    end
  end
end
