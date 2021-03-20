# frozen_string_literal: true

module Pulljoy
  module StateStore
    class Base
      # Loads a state. Returns nil if it doesn't exist.
      #
      # @param repo_full_name [String]
      # @param pr_num [Integer]
      # @return [Pulljoy::State, nil]
      def load(repo_full_name, pr_num)
        raise NotImplementedError
      end

      # Creates or updates a state. If the state exists, it's
      # entirely overwritten by the new state (no merging of contents).
      #
      # @param repo_full_name [String]
      # @param pr_num [Integer]
      # @param state [Pulljoy::State]
      def save(repo_full_name, pr_num, state)
        raise NotImplementedError
      end

      # Deletes a state. Does nothing if the state doesn't exist.
      #
      # @param repo_full_name [String]
      # @param pr_num [Integer]
      def delete(repo_full_name, pr_num)
        raise NotImplementedError
      end

      def release_thread_local_connection; end
    end
  end
end
