class ChangeDateFormat < ActiveRecord::Migration
  def up
  	change_column :steps, :published_on, :datetime
  end

  def down
  	change_column :steps, :published_on, :date
  end
end
