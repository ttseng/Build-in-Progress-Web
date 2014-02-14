class RenameColumnRemixId < ActiveRecord::Migration
  def change
  	rename_column :projects, :remix_id, :remix_ancestry
  end
end
