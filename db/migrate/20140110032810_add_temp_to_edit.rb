class AddTempToEdit < ActiveRecord::Migration
  def change
    add_column :edits, :temp, :boolean
  end
end
