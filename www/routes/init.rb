get '/' do
	haml :main
end

get '/search' do
	fields = {
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
  content_type :json
  query = params[:query]
	if !query || query.empty?
		[]
	else
		query.split(/\s+/).map do |piece|
			*field,str = piece.split(':')
			field = fields[field.first]
			if field==:date && str[RB3Jay::YEAR_RANGE]
				_,y1,y2 = str.match(RB3Jay::YEAR_RANGE).to_a
				y1,y2 = y1.to_i,y2.to_i
				y1,y2 = y2,y1 if y1>y2
				y1.upto(y2).flat_map{ |y| @mpd.where(date:y) }
			else
				@mpd.where( {field=>str}, {limit:RB3Jay::MAX_RESULTS} )
			end
		end
		.inject(:&)
		.uniq[0..RB3Jay::MAX_RESULTS]
		.sort_by(&RB3Jay::SONG_ORDER)
		.map(&:details)
	end.to_json
end

get '/playlists' do

end

helpers do
	def myqueue
		# TODO: cache in session variable?
		playlist_name = "user-#{params['user']}"
		@mpd.playlists.find{ |pl| pl.name==playlist_name } || MPD::Playlist.new( @mpd, playlist:playlist_name )
	end
end

get '/myqueue' do
	content_type :json
	playlist = myqueue
	playlist.details.to_json
end

post '/myqueue/add' do
	playlist = myqueue
	playlist.add params[:file]
	playlist.move params[:file], params[:position] if params[:position]
end

post '/myqueue/remove' do
	playlist = myqueue
	playlist.delete playlist.songs.index{ |song| song.file==params[:file] }
end

not_found do |*a|
  content_type :json
  halt 404, {
  	error:  'URL not found',
  	path:   request.path,
  	params: request.params
  }.to_json
end
