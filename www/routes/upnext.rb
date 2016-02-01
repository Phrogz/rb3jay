class RB3Jay < Sinatra::Application
	# post('/qadd'){ p params; add_to_upnext( params[:songs], params[:user], params[:priority].to_i ) }
	# post('/calc'){ recalc_up_next }

	helpers do
		def add_to_upnext( songs, user, priority=0, add_to_end=false )
			songs = Array(songs)
			start = @mpd.playing? ? 1 : 0
			index = nil
			@mpd.queue[start..-1].find.with_index{ |song,i| prio = song.prio && song.prio.to_i || 0; index=i+start if prio<priority } unless add_to_end
			song_ids = songs.reverse.map{ |path| @mpd.addid(path,index) }
			@mpd.song_priority(priority,{id:song_ids}) if priority>0
			songs.each{ |s| @mpd.set_sticker 'song', s, 'added-by', user }
		end

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
			@mpd.delete((playing_index+1)..-1) if @mpd.queue.length>(playing_index+1)
			@mpd.delete(0..(playing_index-1))  if playing_index>0
		else
			@mpd.clear
		end
	end

	def add_user_queues
		start_time = Time.now
		songs_in_list = Set.new @mpd.queue.map(&:file)
		sql = "SELECT user,sum(duration) FROM song_events WHERE user NOT NULL AND event='play' AND strftime('%Y-%m-%d',`when`)=:today GROUP BY user"
		played_by_user = Hash[ @db[sql,today:Date.today.strftime('%Y-%m-%d')].map(&:values) ]
		queues_by_user = Hash[
			@mpd.playlists
			.select{ |pl| pl.name.start_with?('user-') && !pl.songs.empty? }
			.sort_by(&:name)
			.map{ |pl| [ pl.name.sub('user-',''), pl.songs ] }
		]
		queues_by_user.each{ |user,_| played_by_user[user] ||= 0 }
		until queues_by_user.empty?
			lowest_user = played_by_user.min_by(&:last).first
			if (queue=queues_by_user[lowest_user]) && (song=queue.shift)
				unless songs_in_list.include?(song.file)
					add_to_upnext( song, lowest_user, 1, true )
					played_by_user[lowest_user] += song.track_length
					songs_in_list << song.file
				end
			end
			if !queue || queue.empty?
				played_by_user.delete lowest_user
				queues_by_user.delete lowest_user
			end
		end
		puts "Added user queues in %.1fs" % (Time.now-start_time)
	end

	def add_random_songs
	end
end

