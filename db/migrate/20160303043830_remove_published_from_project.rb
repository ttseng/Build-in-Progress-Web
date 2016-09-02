class RemovePublishedFromProject < ActiveRecord::Migration
  def up
    remove_column :projects, :published
  end

  def down
    add_column :projects, :published, :boolean
  end
end
