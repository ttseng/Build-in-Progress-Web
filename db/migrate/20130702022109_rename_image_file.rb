class RenameImageFile < ActiveRecord::Migration
  def up
  	rename_column :images, :file, :image_path
  end

  def down
  end
end
