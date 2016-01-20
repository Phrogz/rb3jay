%w[ eventmachine thin sinatra faye
	  rack/session/moneta ruby-mpd sequel json ].each{ |lib| require lib }

require_relative 'environment'

def run!
	EM.run do
		Faye::WebSocket.load_adapter('thin')
		rb3jay = RB3Jay.new
		server = Faye::RackAdapter.new(mount:'/', timeout:25)

		dispatch = Rack::Builder.app do
			map('/'){     run rb3jay }
			map('/faye'){ run server }
		end

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
	use Rack::Session::Moneta, key:'rb3jay.session', path:'/', store: :LRUHash

	configure do
		set :threaded, false
	end

	def initialize
		super
		@mpd = MPD.new( ENV['MPD_HOST'], ENV['MPD_PORT'] )
		@mpd.connect
		@faye = Faye::Client.new("http://#{ENV['RB3JAY_HOST']}:#{ENV['RB3JAY_PORT']}/faye")
		watch_for_changes
		require_relative 'model/init'
		@db = connect_to( ENV['MPD_STICKERS'] )
	end

	def watch_for_changes
		watch_status
		watch_playlists
		watch_upnext
	end

	def watch_status
		EM.add_periodic_timer(0.25) do
			if (info=mpd_status) != @last_status
				@last_status = info
				send_status( info )
			end
		end
	end

	def watch_playlists
		EM.defer(
			->( ){ idle_until 'stored_playlist'    },
			->(_){ send_playlists; watch_playlists }
		)
	end

	def watch_upnext
		EM.defer(
			->( ){ idle_until 'playlist', 'database' },
			->(_){ send_next; watch_upnext           }
		)
	end

	def idle_until(*events)
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
			@mpd.queue.slice(0,ENV['RB3JAY_LISTLIMIT'].to_i).map(&:summary)
		end
		def send_next( songs=up_next )
			@faye.publish '/next', songs
		end
		def playlists
			@mpd.playlists.map(&:name).grep(/^(?!user-)/).sort
		end
		def send_playlists( lists=playlists )
			@faye.publish '/playlists', playlists
		end
	end

	# We do not need to send_status/send_next after these
	# because status updates are already sent when they change.
	post('/play'){ @mpd.play                          }
	post('/paws'){ @mpd.pause=true                    }
	post('/skip'){ @mpd.next                          }
	post('/seek'){ @mpd.seek params[:time].to_f       }
	post('/volm'){ @mpd.volume = params[:volume].to_i }

	# Clients poll for information on startup
	get ('/next'){ up_next.to_json   }
	get ('/list'){ playlists.to_json }

	require_relative 'routes/ratings'
	require_relative 'helpers/ruby-mpd-monkeypatches'
	require_relative 'routes/songs'
	require_relative 'routes/myqueue'
end

run!
