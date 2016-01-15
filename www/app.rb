class Symbol; def ~; method(self); end; end
%w[ eventmachine thin sinatra faye
	rack/session/moneta ruby-mpd sequel json ].each(&~:require)
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
		create_client
		require_relative 'model/init'
		@db = connect_to( ENV['MPD_STICKERS'] )
	end

	def create_client
		@faye = Faye::Client.new("http://#{ENV['RB3JAY_HOST']}:#{ENV['RB3JAY_PORT']}/faye")

		# Ocassinoally send the status and/or up-next list only if they have changed
		EM.add_periodic_timer(0.5) do
			if (info=mpd_status) != @last_status
				@last_status = info
				send_status( info )
			end
		end
		EM.add_periodic_timer(2) do
			if (songs=up_next) != @last_next
				@last_next = songs
				send_next( songs )
			end
		end
	end

	before{ content_type :json }

	get '/' do
		content_type :html
		send_file File.expand_path('rb3jay.html',settings.public_folder)
	end

	helpers do
		def mpd_status
			@mpd.status
		end
		def send_status( info=mpd_status )
			@faye.publish '/status', info
		end
		def up_next
			@mpd.queue.slice(0,ENV['RB3JAY_LISTLIMIT'].to_i).map(&:details)
		end
		def send_next( songs=up_next )
			@faye.publish '/next', songs
		end
	end

	post('/play'){ @mpd.play;                    send_status }
	post('/paus'){ @mpd.pause = true;            send_status }
	post('/skip'){ @mpd.next;                    send_status; send_next }
	post('/seek'){ @mpd.seek params[:time].to_f; send_status }
	post('/volm'){ @mpd.volume = params[:volume].to_i; send_status }
	get ('/next'){ up_next.to_json }
	require_relative 'helpers/ruby-mpd-monkeypatches'
	require_relative 'routes/songs'
	require_relative 'routes/myqueue'
	require_relative 'routes/live'
end

run!
