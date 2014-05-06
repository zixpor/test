class CreateTagdbs < ActiveRecord::Migration
  def change
    create_table :tagdbs do |t|
      t.text :post_id
      t.text :profile_picture
      t.text :profile_url
      t.text :profile_name
      t.datetime :post_time
      t.text :type
      t.text :service_type
      t.text :picture_url
      t.text :video_url
      t.text :message
      t.text :source_url
      t.text :tag

      t.timestamps
    end
  end
end
