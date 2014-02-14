class RemoveAuthorFromProject < ActiveRecord::Migration
  def up
  	remove_column :projects, :author
  end

  def down
  end
end
