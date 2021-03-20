# frozen_string_literal: true

require_relative 'base'

module Pulljoy
  module StateStore
    class MemoryStore < Base
      def initialize
        super
        @data = {}
      end

      def load(repo_full_name, pr_num)
        key = [repo_full_name, pr_num]
        state = @data[key]
        state = state.deep_copy if state
        state
      end

      def save(repo_full_name, pr_num, state)
        key = [repo_full_name, pr_num]
        @data[key] = state.deep_copy
      end

      def delete(repo_full_name, pr_num)
        key = [repo_full_name, pr_num]
        @data.delete(key)
      end

      # @return [State, nil]
      def first
        @data[@data.keys[0]] if !@data.empty?
      end

      # @return [Integer]
      def count
        @data.size
      end
    end
  end
end
