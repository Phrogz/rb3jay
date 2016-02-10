class RB3Jay < Sinatra::Application
	helpers do
		def myqueue
			# TODO: clean up the playlist, removing any invalid or duplicate entries
			# TODO: cache in session variable?
			playlist_name = "user-#{params['user']}"
			@mpd.playlists.find{ |pl| pl.name==playlist_name } || MPD::Playlist.new( @mpd, playlist:playlist_name )
		end

		def user_active(login, active:, skip_update:false)
			@user_active_timer ||= {}
			if user = @db[:users][login:login]
				EM.cancel_timer(@user_active_timer[login]) if @user_active_timer[login]
				if user[:active] != active
					@db[:users].filter(login:login).update(active:active)
					@faye.publish("/user-#{login}",{active:active})
					recalc_upnext unless skip_update
				end
				if active
					# Automatically set a user to be inactive after a period of time
					@user_active_timer[login] = EM.add_timer(ENV['RB3JAY_USERIDLE'].to_i) do
						user_active( login, active:false )
					end
				end
			end
		end

		def touch_user
			if (user=params[:user]) && @db[:users][ login:user, active:true ]
				user_active user, active:true
			end
		end
	end

	get '/myqueue' do
		playlist = myqueue
		playlist.songs.map(&:summary).to_json
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

	post('/shuffle'){ shuffle_playlist params[:user]; '"ok"' }

	post '/myqueue/away' do
		user_active params['user'], active:false
	end

	post '/myqueue/active' do
		user_active params['user'], active:true
	end

	post '/rollcall' do
		@db[:users].select_map(:login).each do |login|
			user_active login, active:false, skip_update:true
		end
		recalc_upnext
	end

end