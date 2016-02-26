class RB3Jay < Sinatra::Application
	helpers do
		def commas(int,zero='-')
			if int.nil? || int==0
				zero
			else
				int.to_s.reverse.scan(/\d{1,3}/).join(',').reverse
			end
		end
		def duration(seconds)
			seconds ||= 0
			t=nil
			[].tap do |parts|
				parts << "#{t} day#{   :s if t!=1}" if (t=seconds/86400)>0
				parts << "#{t} hour#{  :s if t!=1}" if (t=seconds/3600%24)>0
				parts << "#{t} minute#{:s if t!=1}" if (t=seconds/60%60)>0
				parts << "#{t} second#{:s if t!=1}" if (t=seconds%60)>0
			end.slice(0,2).join(", ")
		end
	end
	get('/stats') do
		@stats = @mpd.stats
		@user_stats = {}
		songs = @mpd.songs
		songs.group_by{ |song| song.file[%r{^[^/]+}] }.each do |directory,songs|
			# FIXME: this assumes that the directory name is the nice user name
			user_name = directory.capitalize
			@user_stats[user_name] ||= {}
			@user_stats[user_name][:own_songs] = songs.length
			@user_stats[user_name][:song_time] = songs.map(&:track_length).inject(:+)
		end
		@db["SELECT user,count(*) AS ct FROM song_events WHERE user NOT NULL AND event='play' GROUP BY user ORDER BY user"].each do |hash|
			user_name = @user_by_login[ hash[:user] ][:name]
			@user_stats[user_name] ||= {}
			@user_stats[user_name][:play_count] = hash[:ct]
		end
		@db["SELECT user,count(*) AS ct FROM song_events WHERE user NOT NULL AND event='skip' GROUP BY user ORDER BY user"].each do |hash|
			user_name = @user_by_login[ hash[:user] ][:name]
			@user_stats[user_name] ||= {}
			@user_stats[user_name][:skip_count] = hash[:ct]
		end
		@db["SELECT user,rating,count(*) AS ct FROM user_ratings GROUP BY user,rating ORDER BY user"].each do |hash|
			user_name = @user_by_login[ hash[:user] ][:name]
			@user_stats[user_name] ||= {}
			@user_stats[user_name][hash[:rating]] = hash[:ct]
		end
		content_type :html
		haml :stats
	end
end
