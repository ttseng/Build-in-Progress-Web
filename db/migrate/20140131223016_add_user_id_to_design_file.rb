class AddUserIdToDesignFile < ActiveRecord::Migration
  def change
    add_column :design_files, :user_id, :integer
  end
end
