# encoding: utf-8

SERVER_ADDRESS = "bugbot"
SERVER_PORT    = 80

Dir.chdir( File.dirname( __FILE__ ) )
require 'sinatra'
require 'sequel'
require 'haml'
require 'logger'
require 'json'
require 'ruby-mpd'

# require_relative 'minify_resources'

require_relative 'helpers/init'

class RB3Jay < Sinatra::Application
	use Rack::Session::Cookie, key:'rb3jay.session', path:'/', secret:'znoZgood'

	MAX_RESULTS = 500

	YEAR_RANGE = /\A(\d{4})(?:-|\.\.)(\d{4})\Z/
	SONG_ORDER = ->(s){ [
		s.artist ? s.artist.downcase.sub(/\Athe /,'').gsub(/[^ _a-z0-9]+/,'') : "~~~~",
		s.album  || "~~~~",
		s.track  || 99,
		s.title ? s.title.downcase.sub(/\Athe /,'').gsub(/[^ _a-z0-9]+/,'') : "~~~~"
	]	}

	def initialize(args={})
		super()
		@mpd = MPD.new( args[:mpd_host] || ENV['MPD_HOST'], args[:mpd_port] || ENV['MPD_PORT'] )
		@mpd.connect
		require_relative 'model/init'
		@db = connect_to( args[:mpd_sticker_file] || ENV['MPD_STICKER_FILE'] )
	end

	configure :production do
		# set :css_files, :blob
		# set :js_files,  :blob
		# MinifyResources.minify_all

		set :haml, { :ugly=>true }
		set :clean_trace, true

		# Dir.mkdir('logs') unless File.exist?('logs')
		# $logger = Logger.new('logs/common.log','weekly')
		# $logger.level = Logger::WARN

		# $stdout.reopen("logs/output.log", "w")
		# $stdout.sync = true
		# $stderr.reopen($stdout)
	end

	configure :development do
		# set :css_files, MinifyResources::CSS_FILES
		# set :js_files,  MinifyResources::JS_FILES
		$logger = Logger.new(STDOUT)
	end
end

require_relative 'routes/init'

