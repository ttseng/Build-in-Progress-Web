class AddPublishedOnToStep < ActiveRecord::Migration
  def change
    add_column :steps, :published_on, :date
  end
end
