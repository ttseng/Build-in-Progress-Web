class AddRemixToProject < ActiveRecord::Migration
  def change
    add_column :projects, :remix, :integer
  end
end
