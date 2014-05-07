#require 'twitter'
class HashcontrolController < ApplicationController
	@@access_token = ''	
	def instagram_search(tag_name,offset=false)
	    p 'Instagram'
	    count = 0
	    medias = []

	    client = Instagram.client(:access_token => @@access_token)

	    begin
	    	tag =client.tag(tag_name)
	    rescue
	    	@@access_token = session[:ig_token]
	    end
		
	    p 'tag == nil' if tag == nil
	    return medias if tag == nil
		
	    unless offset		
		if tag.media_count > 0
			result = client.tag_recent_media(tag_name)
			medias << result
			count += result.count
			next_max_tag_id = result.pagination.next_max_tag_id
			session[:ig_next_id] = next_max_tag_id
		end
			 
		while next_max_tag_id != nil and count <= 50 do
			result = client.tag_recent_media(tag_name,max_id: next_max_tag_id)
			medias << result
			count += result.count
			next_max_tag_id = result.pagination.next_max_tag_id
			session[:ig_next_id] = next_max_tag_id
		end
	    else
	    	next_max_tag_id = session[:ig_next_id]
		while next_max_tag_id != nil and count <= 50 do
		    result = client.tag_recent_media(tag_name,max_id: next_max_tag_id)
		    medias << result
		    count += result.count
		    next_max_tag_id = result.pagination.next_max_tag_id
		    session[:ig_next_id] = next_max_tag_id
		end
	    end
		
	    medias.flatten!
	     
	    medias.each do |media|
	    	@a = Tagdb.find_by(post_id: media.id, service_type: 'instagram', tag: '#'+tag_name)
		if @a == nil  then
		    post = Tagdb.new
		    post.post_id = media.id
		    post.profile_picture = media.user.profile_picture
		    post.profile_url =  media.user.username
		    post.profile_name = removeSpecialChars(media.user.username)
		    post.post_time = DateTime.strptime(media.created_time,'%s').to_time
		    post.type = 'photo' if media.type == 'image'
		    post.type = 'video' if media.type == 'video'
		    post.service_type = 'instagram'
		    post.picture_url = nil
		    post.video_url = nil
		    post.picture_url = media.images.low_resolution.url if media.type == 'image'
		    post.video_url = media.videos.low_resolution.url if media.type == 'video'
		    post.message = nil
		    post.message = removeSpecialChars(media.caption.text) unless media.caption == nil
		    post.source_url = media.link
		    post.tag = "#"+tag_name
		    post.save
		end
	    end
	    p 'exit instagram'
	 	return medias
	end
	 
	def instagram_auth
		 
	    Instagram.configure do |config|
		config.client_id = '84011e685da0471fa71ca19641bea609'
		config.client_secret = '6972fe2a495f4cabad05eb6a5a576b7c'
	    end
	 
	    redirect_to Instagram.authorize_url(redirect_uri: 'http://hashtag.rails-link.com/callback')
	end
	 
	def callback
	    p "22222"	 
	    response = Instagram.get_access_token(params[:code], redirect_uri: 'http://hashtag.rails-link.com/callback' )
	    @@access_token = response.access_token
	    session[:ig_token] = response.access_token
	 
	    redirect_to root_path
	end
	def fb(text,fb_offset)
		clnt =HTTPClient.new
		uri = URI.parse(URI.encode("https://graph.facebook.com/search"))
		extheader = {'Accept-Language' => 'en,th;q=0.8'}
		@id = 0
		if(fb_offset)
			@id = Tagdb.find_by(post_id: fb_offset)
			if(@id != nil)
			time = (@id.post_time.to_datetime.to_i - 1).to_s
			query = {"q" => text, "access_token" => "1391695174426555|fqyLM9MMQiRYSXQWCUsYEDxZ3DI","limit" => "50",'until' =>time}
			@data=clnt.get_content(uri, query, extheader)	
			end
		else
		query = {"q" => text, "access_token" => "1391695174426555|fqyLM9MMQiRYSXQWCUsYEDxZ3DI","limit" => "50"}
		@data=clnt.get_content(uri, query, extheader)
		end
	        if(@data!=nil)	
		@dataj=JSON.parse(@data)
		count = @dataj["data"].count
		i = 0 
		
		while i<count
		@check = Tagdb.find_by(post_id: @dataj["data"][i]["id"],tag: text)
			if(!@check)
			
				@new = Tagdb.new
				@new.post_id = @dataj["data"][i]["id"]
				@new.profile_picture = "https://graph.facebook.com/"+@dataj["data"][i]["from"]["id"]+"/picture"
				@new.profile_url ="https://www.facebook.com/"+@dataj["data"][i]["from"]["id"]
				@new.profile_name = removeSpecialChars(@dataj["data"][i]["from"]["name"])
				@new.post_time =@dataj["data"][i]["created_time"]
				if( @dataj["data"][i]["type"].to_s=="status")
					@new.type = "message"
				else
					@new.type = @dataj["data"][i]["type"].to_s
				end
				@new.service_type = "facebook"
				if(@dataj["data"][i]["type"].to_s=="photo" || @dataj["data"][i]["type"].to_s == "link")
					@new.picture_url =  @dataj["data"][i]["picture"]
				else
					@new.picture_url = nil
				end
				if(@dataj["data"][i]["type"].to_s=="video")
					@new.video_url = @dataj["data"][i]["source"]
				else
					@new.video_url = nil
				end
				@new.message =  removeSpecialChars(@dataj["data"][i]["message"].to_s+"<br/>"+@dataj["data"][i]["caption"].to_s+"<br/>"+@dataj["data"][i]["description"].to_s)
				@new.source_url = "http://facebook.com/"+@dataj["data"][i]["id"]
				@new.tag = text
				@new.save
			end
			@id = @dataj["data"][i]["id"].to_s
			p @id		
		i=i+1;	
		end
		end
		return @id
	end
	def twittersearch(input,tw_offset)
	# client = Twitter::Streaming::Client.new do |config|
	 	client = Twitter::REST::Client.new do |config|
	 		config.consumer_key        = "qD0yapbhte9uT2dBEDsrTsUzv"
	 		config.consumer_secret     = "eTdTNkUa57OkNe1KEep3crQrmcblQDHfYFfInMy8JNQstKdfT6"
	 		config.access_token        = "373992248-7OFmo7IlwwvjkbIlLA222ypXU4n8uM4kDhuArHav"
	 		config.access_token_secret = "o3MIQ7ld6cQ3Xf09DsPLMyglqFlUGf7ApyXXHEPqZdbaZ"
		end
		if(tw_offset)
		output = client.search(input, :result_type => "recent",:include_entities => true,:max_id => tw_offset.to_i-1).take(50).collect
		else
		p "in this"
		output = client.search(input, :result_type => "recent",:include_entities => true).take(50).collect
		end
		p output.to_a
		return output.to_a
	end
	def twdb(text,tw_offset)
		@tweets = twittersearch(text,tw_offset)	
		twcount = @tweets.count
		i = 0
		id = 0
		while i<twcount
			twcheck = Tagdb.find_by(post_id: @tweets[i].id,tag: text)
			if (!twcheck)
				twnew = Tagdb.new
				twnew.post_id = @tweets[i].id
				#twnew.profile_picture = "http://pbs.twimg.com/profile_images/453501953033506817/pXoDOPM5_normal.jpeg"
				twnew.profile_picture = @tweets[i].user.profile_image_url.to_s
				twnew.profile_url = "http://twitter.com/"+@tweets[i].user.screen_name
				twnew.profile_name = removeSpecialChars(@tweets[i].user.screen_name)
				twnew.post_time = @tweets[i].created_at
				if (@tweets[i].media?)
					twnew.type = "photo"
				else
					twnew.type = "message"
				end
				twnew.service_type = "twitter"
				if (@tweets[i].media?)
					twnew.picture_url = @tweets[i].media[0].media_url.to_s
				else
					twnew.picture_url = nil
				end
				twnew.video_url = nil
				twnew.message = removeSpecialChars(@tweets[i].text)
				#twnew.message = @tweets[i].text.to_s.gsub(/[\u1F60-\u1F64]|[\u2702-\u27B0]|[\u1F68-\u1F6C]|[\u1F30-\u1F70]|[\u2600-\u26ff]|[\u1F601-\u1F64F]|[\u24C2]/, '').chars.select{|i| i.valid_encoding?}.join
				twnew.source_url = "http://twitter.com/"+@tweets[i].user.screen_name+"/statuses/"+@tweets[i].id.to_s
				twnew.tag = text
				twnew.save
			end
		        id = @tweets[i].id
			i = i+1
		end
		return id
	end

	def googleplus(text,gp_offset)
	   p 'google plus'
	   @gcount = 0
	   @clnt = HTTPClient.new
	   @hearder = {'referer'=>'http://rails-link.com:3001/'} #--------------------------------------------------------------
	   while @gcount<5
	   @gcount = @gcount +1
	   if(gp_offset)
	     @query = {'query'=>text,'orderBy' => 'recent' ,'key' => 'AIzaSyCSQtFXMZvC_9z6-OLWa8p7tHmzI-shjJw','pageToken' => gp_offset, 'maxResults' => '20'}
	   else
	     @query = {'query'=>text,'orderBy' => 'recent' ,'key' => 'AIzaSyCSQtFXMZvC_9z6-OLWa8p7tHmzI-shjJw', 'maxResults' => '20'}
	   end
	   @uri = "https://www.googleapis.com/plus/v1/activities"
	   @content = @clnt.get_content(@uri,@query,@hearder)
	   @data = JSON.parse(@content)
	   gp_offset = @data['nextPageToken']
	   @data['items'].each do |d|
	   @a = Tagdb.find_by(post_id: d['id'], service_type: 'googleplus',tag: text)
	   if @a== nil  then
	     if !d['object']['attachments'].nil?
	       d['object']['attachments'].each do |a|
		 t = Tagdb.new
		 @ids = t.id
		 t.message =  removeSpecialChars(d['object']['content'])
		 t.profile_name = removeSpecialChars(d['actor']['displayName'])
		 t.profile_url = d['actor']['url']
		 t.profile_picture = d['actor']['image']['url']
		 t.post_id = d['id']
		 t.post_time = d['published']
		 if(a['objectType']=='album')
		 	t.type ="photo"
                 elsif a['objectType']=='article'
		        t.type = "message"
                 else
		 	t.type = a['objectType']
		 end
		 if a['objectType'] == "photo" 
		   t.picture_url = a['image']['url']
		 end
		 if a['objectType'] == "album"
		   t.picture_url = a['thumbnails'][0]['image']['url']
		 end
		 if a['objectType'] == "video"
		   if a.has_key? 'embed'
		   t.video_url = a['embed']['url']
		   end
		 end
		 t.source_url = d['url']
		 t.service_type = "googleplus"
		 t.tag = text
		 t.save
	       end
	     else
		 t = Tagdb.new
		 @ids = t.id
		 t.message =removeSpecialChars(d['object']['content'])
		 t.profile_name = removeSpecialChars(d['actor']['displayName'])
		 t.profile_url = d['actor']['url']
		 t.profile_picture = d['actor']['image']['url']
		 t.post_id = d['id']
		 t.post_time = d['published']
		 t.source_url = d['url']
		 t.service_type = "googleplus"
		 t.tag = text
		 t.type = "message"
		 t.save
	     end
	   end
	    @token = @data['nextPageToken']
	end
	end
	p 'google plus exit'
	return @token
	
end
	def removeSpecialChars(str)
		return str.gsub(/[^\p{Thai}a-zA-Z0-9 \`\~\!\@\#\$\%\^\&\*\(\)\-\=\_\+\[\]\\\;\'\,\.\/\{\}\|\:\"\<\>\?]*/,"")
		#return str.encode('utf-8' , invalid: :replace, undef: :replace, replace: '')
		#return str.gsub(/[\`\~\!\@\#\$\%\^\&\*\(\)\-\=\_\+\[\]\\\;\'\,\.\/\{\}\|\:\"\<\>\?]/,' ') unless(str.nil?)
		        	
		return ""
    	end

	def  index
		p "1111"
		#redirect_to instagram_auth_path if @@access_token == ''
	end

	def search
		text = '#'+params[:data].to_s
		@searchtext = text
		
		post_offset = params[:offset]
		fb_offset = params[:fb_offset]
		tw_offset = params[:tw_offset]
		gp_offset = params[:gp_offset]
		if params[:fb] then @fbparams = params[:fb] else @fbparams = "1" end
		if params[:tw] then @twparams = params[:tw] else @twparams = "1" end 
		if params[:gplus] then @gparams  = params[:gplus] else @gparams = "1" end 
		if params[:ig] then @igparams = params[:ig] else @igparams = "1" end
		
		if @fbparams == "1" then @fbtick = "true" else @fbtick = "false" end
		if @twparams == "1" then @twtick = "true" else @twtick = "false" end 
		if @gparams == "1" then @gtick  = "true" else @gtick = "false" end 
		if @igparams == "1" then @igtick = "true" else @igtick = "false" end
	@fb_id = -1
	@tw_id=-1
	#-----------------------------------fb--------------------------------------------	
	if @fbparams == "1" 
		@fb_id = fb(text,fb_offset)
	end
	#------------------------------------------------------------------------------------------------------
        
	#-----------------Twitter------------------------	
	if @twparams == "1" 
		p "Fetching Twitter"
		@tw_id = twdb(text,tw_offset)
	end
        #-----------------------------------------------
		#p /p{thai}/.match(params[:data].to_s).to_s	
	#---------------------------------IG--------------------------------------
	if(@igparams == "1" && (/[\p{thai}]*/.match(params[:data].to_s).to_s==""))
		p 'before call instagram'
		igoffset = false
		igoffset = true if params[:offset]
		#@IG = instagram_search(params[:data].to_s,igoffset)
				
	end
	#------------------------------------------------------------------------
	#---------------------------------g+--------------------------------------
	if @gparams == "1"
		@g = googleplus(text,gp_offset)
	end
	#-------------------------------------------------------------------------
	@data = Tagdb.order("UNIX_TIMESTAMP(post_time) DESC").where("tag LIKE ? AND ((service_type='facebook' and ?) or (service_type='twitter' and ?) or (service_type='googleplus' and ?) or (service_type='instagram' and ?)  )",text,@fbparams,@twparams,@gparams,@igparams).limit(50).offset(post_offset)
	#@s = Tagdb.find_by(id: "499")
	#@d = @@access_token
	@nextoffset = (post_offset.to_i+50).to_s
		if params[:layout]=="no" then
			@layout = "no"
			render :layout => false
		end
	end

end
