class AddSavedToImage < ActiveRecord::Migration
  def change
    add_column :images, :saved, :boolean
  end
end
