class RenameRemixInProject < ActiveRecord::Migration
  def up
  	rename_column :projects, :remix, :remix_id
  end

  def down
  end
end
