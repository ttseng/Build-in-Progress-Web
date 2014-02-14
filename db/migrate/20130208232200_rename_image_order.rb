class RenameImageOrder < ActiveRecord::Migration
  def change
  	rename_column :images, :order, :position
  end

end
