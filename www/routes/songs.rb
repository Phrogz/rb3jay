class RB3Jay < Sinatra::Application
	YEAR_RANGE = /\A(\d{4})(?:-|\.\.)(\d{4})\Z/ # "1980-1989" or "1980..1989"
	SONG_ORDER = ->(s){ [
		s.artist ? s.artist.downcase.sub(/\Athe /,'').gsub(/[^ _a-z0-9]+/,'') : "~~~~",
		s.album  || "~~~~",
		s.track  || 99,
		s.title ? s.title.downcase.sub(/\Athe /,'').gsub(/[^ _a-z0-9]+/,'') : "~~~~"
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
		def song_details(file,user)
			user_rating = @db[:user_ratings].where( user:user, uri:file ).select_map(:rating).first
			events  = Hash[ @db["select event,count(*) AS c,max(`when`) AS m from song_events where uri=? group by event",file].map{|h| v=h.values; [v.shift,v] } ]
			details = @mpd.where({file:file},{strict:true}).first.details.merge(
				'rating'  => user_rating,
				'user'    => user,
				'played'  => events['play'] && events['play'].first,
				'skipped' => events['skip'] && events['skip'].first,
				'lastplayed' => events['play'] && (Time.parse(events['play'].last).to_f * 1000).round,
			)
		end
	end

	# See if the song details the client has are correct and detailed; if not, send off the right ones
	post '/checkdetails' do
		song = params[:song]
		file = song[:file]
		%w[track date time disc bpm].each{ |f| song[f] = song[f].to_i if song[f] }
		song.each{ |k,v| song[k]=nil if v=='' }
		details = song_details(file,params['user'])
		if details == song
			'"nochange"'
		else
			@faye.publish '/songdetails', details
			'"needsupdate"'
		end
	end

	get '/search' do
		query = params[:query]
		json = if params[:playlist] && !params[:playlist].empty?
			playlist = @mpd.playlists.find{ |pl| pl.name==params[:playlist] }
			if playlist
				songs = playlist.songs
				query.split(/\s+/).map do |piece|
					*field,str = piece.split(':')
					field = QUERY_FIELDS[field.first]
					if field==:date && str[YEAR_RANGE]
						_,y1,y2 = str.match(YEAR_RANGE).to_a
						y1,y2 = y1.to_i,y2.to_i
						range = y1>y2 ? y2..y1 : y1..y2
						songs = songs.select{ |song| range===song.date }
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
