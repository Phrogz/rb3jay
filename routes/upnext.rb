class RB3Jay < Sinatra::Application
	helpers do
		def recalc_up_next
			clear_all_but_playing
			add_user_queues
			add_random_songs
		end
	end

	def clear_all_but_playing
		status = @mpd.status
		if status[:state]==:play
			playing_index = status[:song]
			queue_count = @mpd.queue.length
			@mpd.command_list do
				delete((playing_index+1)..-1) if queue_count>(playing_index+1)
				delete(0..(playing_index-1))  if playing_index>0
			end
		else
			@mpd.clear
		end
	end

	def add_user_queues
		start_time = lap_time = Time.now
		songs_in_list = Set.new @mpd.queue.map(&:file)
		initial_song_count = songs_in_list.length
		puts "%-20s: %.3fs" % ["songs_in_list",(t=Time.now)-lap_time]; lap_time=t
		sql = "SELECT user,sum(duration) FROM song_events WHERE user NOT NULL AND event='play' AND strftime('%Y-%m-%d',`when`)=:today GROUP BY user"
		played_by_user = Hash[ @db[sql,today:Date.today.strftime('%Y-%m-%d')].map(&:values) ]
		puts "%-20s: %.3fs" % ["played_by_user",(t=Time.now)-lap_time]; lap_time=t
		queues_by_user = Hash[
			@mpd.playlists
			.select{ |pl| pl.name.start_with?('user-') && !pl.songs.empty? }
			.sort_by(&:name)
			.map{ |pl| [ pl.name.sub('user-',''), pl.songs ] }
		]
		queues_by_user.each{ |user,songs| played_by_user[user] ||= 0 }
		puts "%-20s: %.3fs" % ["queues_by_user",(t=Time.now)-lap_time]; lap_time=t

		files_and_users = []
		until queues_by_user.empty?
			lowest_user = played_by_user.min_by(&:last).first
			if (queue=queues_by_user[lowest_user]) && (song=queue.shift)
				unless songs_in_list.include?(song.file)
					files_and_users << [song.file,lowest_user]
					played_by_user[lowest_user] += song.track_length
					songs_in_list << song.file
				end
			end
			if !queue || queue.empty?
				played_by_user.delete lowest_user
				queues_by_user.delete lowest_user
			end
		end
		puts "%-20s: %.3fs" % ["calculate upnext",(t=Time.now)-lap_time]; lap_time=t

		@mpd.command_list do
			files_and_users.each{ |file,_| add file }
		end
		puts "%-20s: %.3fs" % ["add #{files_and_users.length} songs",(t=Time.now)-lap_time]; lap_time=t

		unless files_and_users.empty?
			begin
				@mpd.song_priority(2,[initial_song_count..-1])
			rescue MPD::ServerArgumentError
			end
			puts "%-20s: %.3fs" % ["set song priority",(t=Time.now)-lap_time]; lap_time=t
		end

		@db[:sticker]
		.insert_conflict(:replace)
		.import(
			[:type,:name,:uri,:value],
			files_and_users.map{ |file,user| ['song','added-by',file,user] }
		)
		puts "%-20s: %.3fs" % ["set all stickers",(t=Time.now)-lap_time]; lap_time=t

		puts "%-20s: %.3fs" % ["DONE",Time.now-start_time]
	end

	def add_random_songs
	end
end
