class CreateCategorizations < ActiveRecord::Migration
  def change
    create_table :categorizations do |t|
      t.integer :category_id
      t.integer :project_id

      t.timestamps
    end
    add_index :categorizations, :category_id
    add_index :categorizations, :project_id
    add_index :categorizations, [:category_id, :project_id], unique: true
  end
end
