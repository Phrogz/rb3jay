class RB3Jay < Sinatra::Application
	helpers do
		def recalc_upnext
			clear_all_but_playing
			add_user_queues
			add_random_songs
		end
	end

	get('/users.css') do
		content_type :css
		@db[:users].flat_map do |user|
			[
				"#upnext tr.user-#{user[:login]} td:last-child:after { content:'#{user[:initials]}'; background:#{user[:color]} }",
				"#upnext tr.user-#{user[:login]} td { color:#{user[:color]} }"
			]
		end.join("\n")
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

		@songs_in_list = Set.new @mpd.queue.map(&:file)
		initial_song_count = @songs_in_list.length
		# puts "%-20s: %.3fs" % ["@songs_in_list",(t=Time.now)-lap_time]; lap_time=t

		sql = "SELECT user,sum(duration) FROM song_events WHERE user NOT NULL AND event='play' AND strftime('%Y-%m-%d',`when`)=:today GROUP BY user"
		played_by_user = Hash[ @db[sql,today:Date.today.strftime('%Y-%m-%d')].map(&:values) ]
		# puts "%-20s: %.3fs" % ["played_by_user",(t=Time.now)-lap_time]; lap_time=t

		active_playlists = Set.new @db[:users].filter(active:true).select_map(:login).map{ |s| "user-#{s}" }
		queues_by_user = Hash[
			@mpd.playlists
			.select{ |pl| active_playlists.include?(pl.name) && !pl.songs.empty? }
			.sort_by(&:name)
			.map{ |pl| [ pl.name.sub('user-',''), pl.songs ] }
		]
		original_queue_count = queues_by_user.length
		queues_by_user.each{ |user,songs| played_by_user[user] ||= 0 }
		# puts "%-20s: %.3fs" % ["queues_by_user",(t=Time.now)-lap_time]; lap_time=t

		files_and_users = []
		until queues_by_user.empty?
			lowest_user = played_by_user.min_by(&:last).first
			if (queue=queues_by_user[lowest_user]) && (song=queue.shift)
				unless @songs_in_list.include?(song.file)
					files_and_users << [song.file,lowest_user]
					played_by_user[lowest_user] += song.track_length
					@songs_in_list << song.file
				end
			end
			if !queue || queue.empty?
				played_by_user.delete lowest_user
				queues_by_user.delete lowest_user
			end
		end
		# puts "%-20s: %.3fs" % ["calculate upnext",(t=Time.now)-lap_time]; lap_time=t

		@mpd.command_list do
			files_and_users.each{ |file,_| add file }
		end
		# puts "%-20s: %.3fs" % ["add #{files_and_users.length} songs",(t=Time.now)-lap_time]; lap_time=t

		unless files_and_users.empty?
			begin
				@mpd.song_priority(2,[initial_song_count..-1])
			rescue MPD::ServerArgumentError
			end
			# puts "%-20s: %.3fs" % ["set song priority",(t=Time.now)-lap_time]; lap_time=t
		end

		# This removes the ID for the currently-playing song, which we don't want
		# @db[:sticker].where(name:'added-by').delete

		@db[:sticker]
		.insert_conflict(:replace)
		.import(
			[:type,:name,:uri,:value],
			files_and_users.map{ |file,user| ['song','added-by',file,user] }
		)
		# puts "%-20s: %.3fs" % ["set all stickers",(t=Time.now)-lap_time]; lap_time=t

		@songs_in_list.length

		puts( "Recalculated upnext for #{original_queue_count} users in %.3fs" % (Time.now-start_time) )
	end

	def add_random_songs
		extra_needed = ENV['RB3JAY_NEXTLIMIT'].to_i - @songs_in_list.length
		unless extra_needed<=0
			start_time = t2 = Time.now
			disliked  = Set.new @db[:user_ratings].filter(rating:'hate').or(rating:'bleh').distinct.select_map(:uri)
			puts "%-20s: %.3fs" % ["find disliked",(t=Time.now)-t2]; t2=t

			four_weeks = Date.today - 4*7
			recent = Set.new @db["SELECT uri FROM song_events WHERE `when`>?", four_weeks ].select_map(:uri)
			puts "%-20s: %.3fs" % ["find recent",(t=Time.now)-t2]; t2=t

			disallowed_files = disliked + recent + @songs_in_list
			extra = (@filler - disallowed_files).to_a.slice(0,extra_needed)
			puts "%-20s: %.3fs" % ["sort #{extra_needed} randsongs",(t=Time.now)-t2]; t2=t

			@mpd.command_list{ extra.each{ |file| add file } }
			puts "%-20s: %.3fs" % ["add #{extra_needed} randsongs",(t=Time.now)-t2]; t2=t

			puts( "Added #{extra_needed} files in %.3fs" % (Time.now-start_time) )
		end
	end
end

