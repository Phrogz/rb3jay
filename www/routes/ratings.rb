class RB3Jay < Sinatra::Application
	helpers do
		def set_rating(user,file,rating)
			@db[:user_ratings].insert_conflict(:replace).insert( user:params[:user], uri:file, rating:rating, when:Time.now )
		end
		def get_rating(user,file)
			@db[:user_ratings].where( user:params[:user], uri:file ).select_map(:rating).first || 'zero'
		end
	end
	post '/rate' do
		if params['user']
			%w[love like zero bleh hate].each do |level|
				params[level].each do |file|
					set_rating(params['user'], file, level)
					@faye.publish '/songdetails', song_details(file,params['user'])
				end if params[level]
			end
			'"ok"'
		else
			warn "Cannot rate songs without a 'user'"
		end
	end

	post '/adjust-active-song-rating' do
		change_map = {
			['love',+1] => nil,
			['love',-1] => 'like',
			['like',+1] => 'love',
			['like',-1] => 'zero',
			['zero',+1] => 'like',
			['zero',-1] => 'bleh',
			['bleh',+1] => 'zero',
			['bleh',-1] => 'hate',
			['hate',+1] => 'bleh',
			['hate',-1] => nil,
		}
		file       = @mpd.current_song.file
		old_rating = get_rating(params[:user],file)
		new_rating = change_map[ [old_rating, params[:change].to_i] ]
		if new_rating
			set_rating(params[:user], file, new_rating)
			details = song_details(file,params['user'])
			@faye.publish '/songdetails', details
			new_rating
		else
			old_rating
		end.to_json
	end
end

