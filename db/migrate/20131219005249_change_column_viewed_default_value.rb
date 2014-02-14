class ChangeColumnViewedDefaultValue < ActiveRecord::Migration
  def change
  	change_column :activities, :viewed, :boolean, :default=> false
  end

end
