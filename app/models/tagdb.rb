class Tagdb < ActiveRecord::Base
	attr_accessible :post_id,:profile_picture,:profile_url,:profile_name,:post_time,:type,:service_type,:picture_url,:video_url,:message,:source_url,:tag
	self.inheritance_column = nil
end
