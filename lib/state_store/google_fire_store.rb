# frozen_string_literal: true

require 'google/cloud/firestore'
require 'digest/md5'
require_relative 'base'
require_relative '../state'

module Pulljoy
  module StateStore
    class GoogleFireStore < Base
      # @param config [Pulljoy::StateStore::GoogleFireStoreConfig, Hash]
      def initialize(config)
        super()
        config_hash = config.to_h
        @collection_name = config_hash[:collection_name]
        @gclient = Google::Cloud::Firestore.new(
          **get_firestore_options_from_config_hash(config_hash)
        )
      end

      def load(repo_full_name, pr_num)
        doc = get_doc_ref(repo_full_name, pr_num)
        snapshot = doc.get
        State.new(snapshot.data) if snapshot.exists?
      end

      def save(repo_full_name, pr_num, state)
        doc = get_doc_ref(repo_full_name, pr_num)
        doc.set(state.to_hash)
      end

      def delete(repo_full_name, pr_num)
        doc = get_doc_ref(repo_full_name, pr_num)
        doc.delete
      end

      private

      # @param config [Hash]
      def get_firestore_options_from_config_hash(config_hash)
        result = config_hash.dup
        result.delete(:collection_name)
        result
      end

      def get_doc_ref(repo_full_name, pr_num)
        key = create_key(repo_full_name, pr_num)
        @gclient.col(@collection_name).doc(key)
      end

      # The main reason why we make a hash, is because Firestore
      # discourages document names in a narrow range.
      # https://firebase.google.com/docs/firestore/best-practices#high_read_write_and_delete_rates_to_a_narrow_document_range
      def create_key(repo_full_name, pr_num)
        Digest::MD5.hexdigest("#{repo_full_name}\n#{pr_num}")
      end
    end
  end
end
