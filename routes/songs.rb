class RB3Jay < Sinatra::Application
	YEAR_RANGE = /\A(\d{4})(?:-|\.\.)(\d{4})\Z/ # "1980-1989" or "1980..1989"
	SONG_ORDER = ->(s){ [
		s.artist ? s.artist.downcase.sub(/\Athe /,'').gsub(/[^ _a-z0-9]+/,'') : "~~~~",
		# s.album  || "~~~~",
		# s.track  || 99,
		s.title ? s.title.downcase.sub(/\Athe /,'').gsub(/[^ _a-z0-9]+/,'') : "~~~~",
		s.year  ? -s.year.to_i : 999
	]	}

	# Mapping query prefix that the user types to the MPD field to query
	QUERY_FIELDS = {
		"file"        => :file,
		"filename"    => :file,
		"artist"      => :artist,
		"album"       => :album,
		"albumartist" => :albumartist,
		"title"       => :title,
		"genre"       => :genre,
		"date"        => :date,
		"name"        => :title,
		"year"        => :date,
		"n"           => :title,
		"t"           => :title,
		"a"           => :artist,
		"A"           => :album,
		"b"           => :album,
		"y"           => :date,
		"g"           => :genre,
		"f"           => :file,
		nil           => :any
	}

	# Fields to search when no query prefix is supplied AND we are searching playlists
	# ordered in terms of likelihood for optimal performance
	PLAYLIST_ANY = %w[ title artist genre album date albumartist composer ]

	helpers do
		def song_details(file)
			ratings = Hash[ @db[:user_ratings].where(uri:file).select_map([:user,:rating]) ]
			events  = Hash[ @db["select event,count(*) AS c,max(`when`) AS m from song_events where uri=? group by event",file].map{|h| v=h.values; [v.shift,v] } ]
			song = @mpd.where({file:file},{strict:true}).first
			song.details.merge(
				'ratings'    => ratings,
				'played'     => events['play'] && events['play'].first,
				'skipped'    => events['skip'] && events['skip'].first,
				'lastplayed' => events['play'] && (Time.parse(events['play'].last).to_f * 1000).round,
			) if song
		end
	end

	# See if the song details the client has are correct and detailed; if not, send off the right ones
	post '/checkdetails' do
		if song=params[:song]
			file = song[:file]
			%w[track date time disc bpm].each{ |f| song[f] = Array(song[f]).first.to_i if song[f] }
			song.each{ |k,v| song[k]=nil if v=='' }
			details = song_details(file)
			case details
				when nil
					@faye.publish '/songdetails', {file:file,deleted:true}
					'"deleted"'
				when song
					'"nochange"'
				else
					@faye.publish '/songdetails', details
					'"needsupdate"'
			end
		else
		end
	end

	get '/search' do
		query = params[:query]
		json = if params[:playlist] && !params[:playlist].empty?
			songs = case params[:playlist]
			when nil,"" then nil
			when "øplayedø"
				uris = @db[
					"SELECT uri,max(`when`) AS played FROM song_events WHERE user=? AND event='play' GROUP BY uri ORDER BY played LIMIT ?",
					params[:user],
					ENV['RB3JAY_LISTLIMIT'].to_i
				].select_map(:uri)

				@mpd.command_list(:songs){ uris.each{ |uri| where({file:uri},{strict:true}) } }

			when "øilikeyø"
				rating_by_uri = Hash[
					@db[
						"SELECT uri,rating FROM user_ratings WHERE user=? AND (rating='like' OR rating='love') ORDER BY rating DESC LIMIT ?",
						params[:user],
						ENV['RB3JAY_LISTLIMIT'].to_i
					].select_map([:uri,:rating])
				]

				@mpd.command_list(:songs){ rating_by_uri.keys.each{ |uri| where({file:uri},{strict:true}) } }
				.sort_by{ |s| [
					rating_by_uri[s.file]=='love' ? 0 : 1,
					*SONG_ORDER[s]
				]}

			else
				if pl=@mpd.playlists.find{ |pl| pl.name==params[:playlist] }
					pl.songs.select(&:time) # If @time is nil, the file likely no longer exists.
				end
			end

			if songs
				query.split(/\s+/).map do |piece|
					*field,str = piece.split(':')
					field = QUERY_FIELDS[field.first]
					if field==:date && str[YEAR_RANGE]
						_,y1,y2 = str.match(YEAR_RANGE).to_a
						y1,y2 = y1.to_i,y2.to_i
						range = y1>y2 ? y2..y1 : y1..y2
						songs = songs.select{ |song| range===song.year }
					else
						re = /#{Regexp.escape(str)}/i
						if field==:any
							songs = songs.select{ |song| PLAYLIST_ANY.find{ |field| song.send(field) =~ re } }
						else
							songs = songs.select{ |song| song.send(field).to_s =~ re  }
						end
					end
				end
				songs
			else
				warn "Could not find playlist #{params[:playlist]}"
				[]
			end
		else
			if !query || query.empty?
				@mpd.where(file:'.')
			else
				query.split(/\s+/).map do |piece|
					*field,str = piece.split(':')
					field = QUERY_FIELDS[field.first]
					if field==:date && str[YEAR_RANGE]
						_,y1,y2 = str.match(YEAR_RANGE).to_a
						y1,y2 = y1.to_i,y2.to_i
						y1,y2 = y2,y1 if y1>y2
						y1.upto(y2).flat_map{ |y| @mpd.where(date:y) }
					else
						@mpd.where( field=>str )
					end
				end
				.inject(:&)
			end
			.sort_by(&SONG_ORDER)
			.uniq
		end
		.slice(0,ENV['RB3JAY_LISTLIMIT'].to_i)
		.map(&:details)
		.to_json

		# if json!=session[:lastsonglist] || params[:force]
		# 	session[:lastsonglist] = json
		# else
		# 	'{"nochange":1}'
		# end
	end
end
