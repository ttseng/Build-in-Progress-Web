class RemoveUrlFromDesignFiles < ActiveRecord::Migration
  def change
  	remove_column :design_files, :url
  end
end
