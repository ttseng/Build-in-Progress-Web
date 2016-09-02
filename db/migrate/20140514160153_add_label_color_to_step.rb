class AddLabelColorToStep < ActiveRecord::Migration
  def change
    add_column :steps, :label_color, :string
  end
end
