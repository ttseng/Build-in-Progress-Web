class AddAncestryToStep < ActiveRecord::Migration
  def change
    add_column :steps, :ancestry, :string
    add_index :steps, :ancestry
  end
end
