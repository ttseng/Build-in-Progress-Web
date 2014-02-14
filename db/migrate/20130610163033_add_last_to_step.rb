class AddLastToStep < ActiveRecord::Migration
  def change
    add_column :steps, :last, :boolean
  end
end
