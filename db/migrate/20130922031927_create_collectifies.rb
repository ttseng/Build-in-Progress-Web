class CreateCollectifies < ActiveRecord::Migration
  def change
    create_table :collectifies do |t|
      t.integer :collection_id
      t.integer :project_id

      t.timestamps
    end
	add_index :collectifies, :collection_id
    add_index :collectifies, :project_id
    add_index :collectifies, [:collection_id, :project_id], unique: true
  end
end
