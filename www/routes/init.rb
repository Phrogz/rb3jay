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
			@mpd.where( fields[field.first] => str)
		end
		.inject(:&)
		.uniq
		.sort_by(&RB3Jay::SONG_ORDER)
		.map(&:summary)
	end.to_json
end

get '/playlists' do

end

not_found do |*a|
  content_type :json
  halt 404, {
  	error:  'URL not found',
  	path:   request.path,
  	params: request.params
  }.to_json
end
