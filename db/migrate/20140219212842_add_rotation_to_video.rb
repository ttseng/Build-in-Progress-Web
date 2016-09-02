class AddRotationToVideo < ActiveRecord::Migration
  def change
    add_column :videos, :rotation, :integer
  end
end
