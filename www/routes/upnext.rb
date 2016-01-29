class RB3Jay < Sinatra::Application
	post('/qadd'){ add_to_upnext( params[:songs], params[:user], params[:priority].to_i ) }
	post('/calc'){ recalc_up_next }

	helpers do
		def add_to_upnext( songs, user, priority=0 )
			songs = Array(songs)
			start = @mpd.playing? ? 1 : 0
			index = nil
			@mpd.queue[start..-1].find.with_index{ |song,i| prio = song.prio && song.prio.to_i || 0; index=i+start if prio<priority }
			song_ids = songs.reverse.map{ |path| @mpd.addid(path,index) }
			@mpd.song_priority(priority,{id:song_ids}) if priority>0
			songs.each{ |s| @mpd.set_sticker 'song', s, 'added-by', user }
			'"done"'
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
		queues = @mpd.playlists.select{ |pl| pl.name.start_with?('user-') }.sort_by(&:name).map(&:songs)
		most   = queues.map(&:length).max
		first,*rest = queues
		interleaved = (first + [nil]*(most-first.length)).zip(*rest).flatten.compact
		first_index = @mpd.queue.length
		# add_to_upnext( interleaved, )
		interleaved.each{ |song| @mpd.add(song.file) }
		@mpd.song_priority( 1, [first_index..-1] )
	end

	def add_random_songs
	end
end

