class AddBuiltToProject < ActiveRecord::Migration
  def change
    add_column :projects, :built, :boolean
  end
end
