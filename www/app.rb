%w[ eventmachine thin sinatra faye sequel set
	  rack/session/moneta ruby-mpd json time ].each{ |lib| require lib }

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
		watch_for_subscriptions
		watch_for_changes
		require_relative 'model/init'
		@db = connect_to( ENV['MPD_STICKERS'] )
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
			end
		end
	end

	def watch_for_changes
		watch_status
		watch_playlists
		watch_player
		watch_upnext
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
						@previous_song = @mpd.song_with_id(info[:songid])
					elsif @previous_song.id != info[:songid]
						if @previous_time / @previous_song.track_length > SKIP_PERCENT
							stickers = @mpd.list_stickers 'song', @previous_song.file
							record_event 'play', stickers['added-by']
						end
						@previous_song = @mpd.song_with_id(info[:songid])

						# Remove the newly-playing song from the playist it game from
						if user=@mpd.list_stickers('song', @previous_song.file)['added-by']
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

	def watch_playlists
		EM.defer(
			->( ){ idle_until 'stored_playlist'    },
			->(_){
				send_playlists
				recalc_up_next
				watch_playlists
			}
		)
	end

	def watch_upnext
		EM.defer(
			->( ){ idle_until 'playlist', 'database' },
			->(_){ send_next; watch_upnext           }
		)
	end

	def watch_player
		EM.defer(
			->( ){ idle_until 'player' },
			->(_){
				# recalc_up_next
				watch_player
			}
		)
	end

	def idle_until(*events)
		# This is a synchronous blocking call, that will
		# return when one of the events finally occurs
		`mpc -h #{ENV['MPD_HOST']} -p #{ENV['MPD_PORT']} idle #{events.join(' ')}`
	end

	before{ content_type :json }

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
			adders = @mpd.find_sticker('song','','added-by')
			{ done: @db[:song_events].order(:when).select(:uri___file,:user).last(3).reverse,
				next: @mpd.queue.slice(0,ENV['RB3JAY_LISTLIMIT'].to_i).map(&:summary).map{ |info| info.merge!('added-by'=>adders[info['file']]) } }
		end
		def send_next
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
			@faye.publish "/playlist/#{user}", playlist_songs_for(user,list)
		end
	end

	# We do not need to send a response after these because
	# updates are automatically pushed based on changes.
	post('/play'){ @mpd.play                                    ; '"ok"' }
	post('/paws'){ @mpd.pause=true                              ; '"ok"' }
	post('/skip'){ @mpd.next; record_event('skip',params[:user]); '"ok"' }
	post('/seek'){ @mpd.seek params[:time].to_f                 ; '"ok"' }
	post('/volm'){ @mpd.volume = params[:volume].to_i           ; '"ok"' }

	post('/shuffle'){ shuffle_playlist params[:user]            ; '"ok"' }

	require_relative 'routes/ratings'
	require_relative 'routes/songs'
	require_relative 'routes/myqueue'
	require_relative 'routes/upnext'
end

run!
