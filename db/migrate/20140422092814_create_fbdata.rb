class CreateFbdata < ActiveRecord::Migration
  def change
    create_table :fbdata do |t|
      t.text :data
      t.text :postid

      t.timestamps
    end
  end
end
