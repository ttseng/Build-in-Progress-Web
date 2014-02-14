class AddDesignFilePathToDesignFiles < ActiveRecord::Migration
  def change
    add_column :design_files, :design_file_path, :string
  end
end
