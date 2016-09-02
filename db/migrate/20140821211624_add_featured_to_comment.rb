class AddFeaturedToComment < ActiveRecord::Migration
  def change
    add_column :comments, :featured, :boolean
  end
end
