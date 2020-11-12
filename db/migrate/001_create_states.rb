# frozen_string_literal: true

class CreateStates < ActiveRecord::Migration[5.2]
  def change
    create_table :states, id: false do |t|
      t.primary_keys [:repo, :pr_num]
      t.string :repo, null: false
      t.integer :pr_num, null: false
      t.string :state_name, null: false
      t.string :review_id
      t.string :commit_sha
      t.timestamp :created_at, null: false
      t.timestamp :updated_at, null: false
    end
  end
end
