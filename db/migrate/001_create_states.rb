class CreateStates < ActiveRecord::Migration[5.2]
  def change
    create_table :states do |t|
      t.string :state_name, null: false
      t.string :review_id
      t.string :commit_sha
      t.timestamp :created_at, null: false
      t.timestamp :updated_at, null: false
    end
  end
end
