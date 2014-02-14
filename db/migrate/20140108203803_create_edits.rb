class CreateEdits < ActiveRecord::Migration
  def change
    create_table :edits do |t|
      t.datetime :started_editing_at
      t.belongs_to :user
      t.belongs_to :step
      t.belongs_to :project
      t.timestamps
    end
  end
end
