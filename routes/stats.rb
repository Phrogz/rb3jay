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
		def time(label,&blk)
			t1 = Time.now
			blk.call.tap{ puts "%.3fs : #{label}" % (Time.now-t1) }
		end
	end
	get('/stats') do
		@stats = @mpd.stats

		timing = {}; t=Time.now

		songs = @mpd.songs
		songs_by_file = songs.map{ |s| [s.file,s] }.to_h
		timing["songs by file"] = Time.now-t; t=Time.now

		@user_stats = {}
		songs.group_by{ |song| song.file[%r{^[^/]+}] }.each do |directory,songs|
			# FIXME: this assumes that the directory name is the nice user name
			user_name = directory.capitalize
			@user_stats[user_name] ||= {}
			@user_stats[user_name][:own_songs] = songs.length
			@user_stats[user_name][:song_time] = songs.map(&:track_length).inject(:+)
		end
		timing["user library"] = Time.now-t; t=Time.now

		@db["SELECT user,count(*) AS ct FROM song_events WHERE user NOT NULL AND event='play' GROUP BY user ORDER BY user"].each do |hash|
			user_name = @user_by_login[ hash[:user] ][:name]
			@user_stats[user_name] ||= {}
			@user_stats[user_name][:play_count] = hash[:ct]
		end
		timing["user plays"] = Time.now-t; t=Time.now

		@db["SELECT user,count(*) AS ct FROM song_events WHERE user NOT NULL AND event='skip' GROUP BY user ORDER BY user"].each do |hash|
			user_name = @user_by_login[ hash[:user] ][:name]
			@user_stats[user_name] ||= {}
			@user_stats[user_name][:skip_count] = hash[:ct]
		end
		timing["user skips"] = Time.now-t; t=Time.now

		@db["SELECT user,rating,count(*) AS ct FROM user_ratings GROUP BY user,rating ORDER BY user"].each do |hash|
			user_name = @user_by_login[ hash[:user] ][:name]
			@user_stats[user_name] ||= {}
			@user_stats[user_name][hash[:rating]] = hash[:ct]
		end
		timing["user ratings"] = Time.now-t; t=Time.now

		@most_skipped = @db["SELECT uri,count(*) AS skips FROM song_events WHERE event='skip' GROUP BY uri ORDER BY skips DESC LIMIT 30"].map do |hash|
			[ songs_by_file[hash[:uri]] || hash[:uri], hash[:skips] ] if hash[:skips]>1
		end.compact
		timing["most skipped"] = Time.now-t; t=Time.now

		@most_played = @db["SELECT uri,count(*) AS plays FROM song_events WHERE event='play' GROUP BY uri ORDER BY plays DESC LIMIT 30"].map do |hash|
			[ songs_by_file[hash[:uri]] || hash[:uri], hash[:plays] ] if hash[:plays]>1
		end.compact
		timing["most played"] = Time.now-t; t=Time.now

		ratings_by_uri = {}
		@db["SELECT uri, rating, count(*) AS ct FROM user_ratings GROUP BY uri, rating ORDER BY ct, uri"]
			.each{ |h| (ratings_by_uri[h[:uri]] ||= {})[h[:rating]] = h[:ct] }
		ratings_by_uri.each do |uri,ratings|
			positive = (ratings['love']||0)*1.5 + (ratings['like']||0)*1.0
			negative = (ratings['hate']||0)*3.2 + (ratings['bleh']||0)*1.5
			ratings[:score] = positive - negative
			ratings[:fight] = ((ratings['love']||0)*2+(ratings['like']||0))*((ratings['bleh']||0)+(ratings['hate']||0)*2)
		end
		@songs_by_rating = ratings_by_uri
		                   .sort_by{ |uri,ratings| -ratings[:score]  }
		                   .map{ |uri,ratings| [songs_by_file[uri],ratings] if songs_by_file[uri] }
		                   .compact
		@contested_songs = ratings_by_uri
		                   .reject{ |uri,ratings| ratings[:fight]==0 }
		                   .sort_by{ |uri,ratings| [-ratings[:fight],-ratings[:score]] }
		                   .map{ |uri,ratings| [songs_by_file[uri],ratings] if songs_by_file[uri] }
		                   .compact

		timing["interesting ratings"] = Time.now-t; t=Time.now

		@dups = songs.select{ |s| s.title && s.artist }
		             .group_by{ |s| [s.title.downcase.gsub(/\W+/,''), s.artist.downcase, (s.track_length/10.0).round] }
		             .reject{ |sig,a| a.length==1 }
		             .sort_by{ |sig,a| [-a.length,sig[1],sig[0]] }
		timing["duplicates"] = Time.now-t; t=Time.now

		template = "%#{timing.keys.map(&:length).max}s: %.3fs"
		puts timing.map{ |label,seconds| template % [label,seconds] }

		content_type :html
		haml :stats
	end
end
