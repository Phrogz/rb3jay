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
		@user_stats = {}

		songs = @mpd.songs
		songs_by_file = songs.map{ |s| [s.file,s] }.to_h

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

		@most_skipped = @db["SELECT uri,count(*) AS skips FROM song_events WHERE event='skip' GROUP BY uri ORDER BY skips DESC LIMIT 30"].map do |hash|
			[ songs_by_file[hash[:uri]] || hash[:uri], hash[:skips] ] if hash[:skips]>1
		end.compact

		@most_played = @db["SELECT uri,count(*) AS plays FROM song_events WHERE event='play' GROUP BY uri ORDER BY plays DESC LIMIT 30"].map do |hash|
			[ songs_by_file[hash[:uri]] || hash[:uri], hash[:plays] ] if hash[:plays]>1
		end.compact

		@dups = songs.select{ |s| s.title && s.artist }
		             .group_by{ |s| [s.title.downcase.gsub(/\W+/,''), s.artist.downcase, (s.track_length/10.0).round] }
		             .reject{ |sig,a| a.length==1 }
		             .sort_by{ |sig,a| [-a.length,sig[1],sig[0]] }

		content_type :html
		haml :stats
	end
end
