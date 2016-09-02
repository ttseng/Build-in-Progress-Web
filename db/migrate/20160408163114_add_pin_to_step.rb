class AddPinToStep < ActiveRecord::Migration
  def change
    add_column :steps, :pin, :string
  end
end
