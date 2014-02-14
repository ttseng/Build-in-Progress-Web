class RenameNumberColumn < ActiveRecord::Migration
  def up
  	rename_column :steps, :number, :position
  end

  def down
  end
end
