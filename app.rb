%w[ eventmachine thin sinatra faye sequel set
	  rack/session/moneta ruby-mpd json time digest ].each{ |lib| require lib }

require_relative 'environment'
require_relative 'helpers/ruby-mpd-monkeypatches'

def run!
	EM.run do
		Faye::WebSocket.load_adapter('thin')
		server = Faye::RackAdapter.new(mount:'/', timeout:25)
		rb3jay = RB3Jay.new( server )

		dispatch = Rack::Builder.app do
			map('/'){     run rb3jay }
			map('/faye'){ run server }
		end

		ENV['RACK_ENV'] = 'production'

		Rack::Server.start({
			app:     dispatch,
			Host:    ENV['RB3JAY_HOST'],
			Port:    ENV['RB3JAY_PORT'],
			server:  'thin',
			signals: false,
		})
	end
end

class RB3Jay < Sinatra::Application
	SKIP_PERCENT = 0.6
	use Rack::Session::Moneta, key:'rb3jay.session', path:'/', store: :LRUHash

	configure do
		set :threaded, false
	end

	def initialize( faye_server )
		super()
		@server = faye_server
		@mpd = MPD.new( ENV['MPD_HOST'], ENV['MPD_PORT'] )
		@mpd.connect
		@faye = Faye::Client.new("http://#{ENV['RB3JAY_HOST']}:#{ENV['RB3JAY_PORT']}/faye")
		watch_status
		watch_for_subscriptions
		watch_for_changes
		require_relative 'model/init'
		@db = connect_to( ENV['MPD_STICKERS'] )
		@user_by_login = Hash[ @db[:users].all.map{|u| [u[:login],u] } ]
		prepare_filler
	end

	def watch_for_subscriptions
		@server.on(:subscribe) do |client_id, channel|
			if user=channel[/startup-(.+)/,1]
				@faye.publish channel, {
					playlists:playlists,
					myqueue:playlist_songs_for(user),
					upnext:up_next,
					status:mpd_status
				}
				user_active user, active:true
			end
		end
	end

	def watch_for_changes
		handle_event = {
			"stored_playlist" => ->{ send_playlists; recalc_upnext },
			"playlist"        => ->{ send_upnext },
			"database"        => ->{ prepare_filler },
		}
		EM.defer(
			->( ){
				# This is a synchronous blocking call, that will
				# return when one of the events finally occurs.
				# TODO: implement @mpd.idle in ruby-mpd and move this to there
				`mpc -h #{ENV['MPD_HOST']} -p #{ENV['MPD_PORT']} idle #{handle_event.keys.join(' ')}`.strip
			},
			->(change){
				watch_for_changes
				handle_event[change].call
			}
		)
	end

	def prepare_filler
		@filler = Set.new @mpd.songs.map(&:file).sort_by{ |file| Digest::MD5.digest(file) }
	end

	def watch_status
		@previous_song = nil
		@previous_time = nil
		EM.add_periodic_timer(0.5) do
			if (info=mpd_status) != @last_status
				@last_status = info
				send_status( info )
				if info[:songid]
					if !@previous_song
						@previous_song = @mpd.song_with_id(info[:songid]) rescue nil
					elsif @previous_song.id != info[:songid]
						@mpd.delete_sticker('song', @previous_song.file, 'added-by') if @mpd.list_stickers('song', @previous_song.file)['added-by']
						if @previous_time / @previous_song.track_length > SKIP_PERCENT
							stickers = @mpd.list_stickers 'song', @previous_song.file rescue nil # If the previous song was removed from the database, this will error
							record_event 'play', stickers['added-by'] if stickers
						end
						@previous_song = @mpd.song_with_id(info[:songid]) rescue nil

						if user=@mpd.list_stickers('song', @previous_song.file)['added-by']
							# Remove the newly-playing song from the playist it came from
							if queue=@mpd.playlists.find{ |pl| pl.name=="user-#{user}" }
								if index=queue.songs.index{ |song| song.file==@previous_song.file }
									queue.delete index
									send_playlist_for user, queue
								end
							end
						end
					end
					@previous_time = info[:elapsed]
				end
			end
		end
	end

	def record_event( event, user=nil )
		if @previous_song
			@db[:song_events] << {
				user:     user,
				event:    event,
				uri:      @previous_song.file,
				duration: @previous_time,
				when:     Time.now
			}
		end
	end

	before do
		content_type :json
		touch_user
	end

	get '/' do
		content_type :html
		send_file File.expand_path('index.html',settings.public_folder)
	end

	helpers do
		def mpd_status
			current = @mpd.current_song
			@mpd.status.merge(file:current && current.file)
		end
		def send_status( info=mpd_status )
			@faye.publish '/status', info
		end
		def up_next
			played = @db[:song_events].order(:when).select(:uri___file,:user).last(3).reverse.map do |hash|
				hash.merge! user:hash[:user]
			end
			adders = @mpd.find_sticker('song','','added-by')
			coming = @mpd.queue.slice(0,ENV['RB3JAY_LISTLIMIT'].to_i).map(&:summary).map do |info|
				info.merge!('user' => adders[info['file']])
			end
			{ done:played, next:coming }
		end
		def send_upnext
			@faye.publish '/next', up_next
		end
		def playlists
			@mpd.playlists.map(&:name).grep(/^(?!user-)/).sort
		end
		def send_playlists( lists=playlists )
			@faye.publish '/playlists', playlists
		end
		def playlist_songs_for(user,list=nil)
			list ||= @mpd.playlists.find{ |pl| pl.name=="user-#{user}" }
			if list
				missing = list.songs.map.with_index{ |song,i| i unless @mpd.where({file:song.file},{strict:true}).first }.compact
				missing.reverse.each{ |index| list.delete(index) }
				list.songs.map(&:summary)
			else
				[]
			end
		end
		def shuffle_playlist(user)
			list = @mpd.playlists.find{ |pl| pl.name=="user-#{user}" }
			songs = list.songs
			songs.map.with_index.to_a.shuffle.each.with_index do |(song,old_index),new_index|
				list.move old_index, new_index
			end
			send_playlist_for(user,list)
		end
		def send_playlist_for(user,list=nil)
			@faye.publish "/user-#{user}", {myqueue:playlist_songs_for(user,list)}
		end
	end

	# We do not need to send a response after these because
	# updates are automatically pushed based on changes.
	post('/play'){ @mpd.play                                    ; '"ok"' }
	post('/paws'){ @mpd.pause=true                              ; '"ok"' }
	post('/skip'){ @mpd.next; record_event('skip',params[:user]); '"ok"' }
	post('/seek'){ @mpd.seek params[:time].to_f                 ; '"ok"' }
	post('/volm'){ @mpd.volume = params[:volume].to_i           ; '"ok"' }
	post('/scan'){ @mpd.update                                  ; '"ok"' } # TODO: look up user account and scan only that directory

	get('/users'){ @user_by_login.values.sort_by{ |u| u[:name] }.to_json }

	require_relative 'routes/ratings'
	require_relative 'routes/songs'
	require_relative 'routes/myqueue'
	require_relative 'routes/upnext'
end

run!
