class RemoveDescriptionFromProject < ActiveRecord::Migration
  def up
    remove_column :projects, :description
  end

  def down
    add_column :projects, :description, :string
  end
end
