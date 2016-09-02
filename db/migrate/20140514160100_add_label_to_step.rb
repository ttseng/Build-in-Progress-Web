class AddLabelToStep < ActiveRecord::Migration
  def change
    add_column :steps, :label, :boolean
  end
end
