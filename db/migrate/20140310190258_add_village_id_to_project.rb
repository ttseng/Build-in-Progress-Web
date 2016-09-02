class AddVillageIdToProject < ActiveRecord::Migration
  def change
    add_column :projects, :village_id, :integer
  end
end
