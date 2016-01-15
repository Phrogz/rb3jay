class RB3Jay < Sinatra::Application
	helpers do
		def myqueue
			# TODO: clean up the playlist, removing any invalid or duplicate entries
			# TODO: cache in session variable?
			playlist_name = "user-#{params['user']}"
			@mpd.playlists.find{ |pl| pl.name==playlist_name } || MPD::Playlist.new( @mpd, playlist:playlist_name )
		end
	end

	get '/myqueue' do
		playlist = myqueue
		playlist.details.to_json
	end

	post '/myqueue/add' do
		playlist = myqueue
		files = params[:files]
		files.reverse! if params[:position]
		files.each do |file|
			playlist.add file
			playlist.move params[:file], params[:position] if params[:position]
		end
	end

	post '/myqueue/remove' do
		playlist = myqueue
		params[:files].each do |file|
			playlist.delete playlist.songs.index{ |song| song.file==file }
		end
	end
end