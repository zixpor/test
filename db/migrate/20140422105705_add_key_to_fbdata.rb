class AddKeyToFbdata < ActiveRecord::Migration
  def change
    add_column :fbdata, :key, :text
  end
end
