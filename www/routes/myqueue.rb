class RB3Jay < Sinatra::Application
	helpers do
		def myqueue
			# TODO: cache in session variable?
			playlist_name = "user-#{params['user']}"
			@mpd.playlists.find{ |pl| pl.name==playlist_name } || MPD::Playlist.new( @mpd, playlist:playlist_name )
		end
	end

	get '/myqueue' do
		# TODO: clean up the playlist, removing any invalid or duplicate entries
		playlist = myqueue
		playlist.details.to_json
	end

	post '/myqueue/add' do
		# TODO: clean up the playlist, removing any invalid or duplicate entries
		playlist = myqueue
		playlist.add params[:file]
		playlist.move params[:file], params[:position] if params[:position]
	end

	post '/myqueue/remove' do
		# TODO: clean up the playlist, removing any invalid or duplicate entries
		playlist = myqueue
		playlist.delete playlist.songs.index{ |song| song.file==params[:file] }
	end
end