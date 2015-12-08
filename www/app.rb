# encoding: utf-8

SERVER_ADDRESS = "bugbot"
SERVER_PORT    = 80

Dir.chdir( File.dirname( __FILE__ ) )
require 'sinatra'
require 'haml'
require 'logger'
require 'json'
require 'ruby-mpd'

# require_relative 'minify_resources'

# TODO: move these monkeypatches to an appropriate spot
class MPD::Playlist
	def summary
		{
			name:  name,
			songs: songs.length,
			code:  nil
		}
	end
	def details
		summary.merge( songs:songs.map(&:summary) )
	end
end

class MPD::Song
	def summary
		{
			id:      file.gsub(' ','💔'),
			file:    file,
			title:   title,
			artist:  artist,
			album:   album,
			genre:   genre,
			date:    date,
			time:    time && time.respond_to?(:last) ? time.last : time,
			rank:    0.5,    #TODO: calculate song rankings
  		artwork: nil     #TODO: extract and store song artwork
		}
	end
	def details
		summary.merge({
			modified:    modified,
			track:       track,
			composer:    composer,
			disc:        disc,
			albumartist: albumartist,
			bpm:         bpm
		})
	end
	def hash
		file.hash
	end
	def eql?(song2)
		file == song2.file
	end
end


class RB3Jay < Sinatra::Application
	use Rack::Session::Cookie, key:'rb3jay.session', path:'/', secret:'znogood'

	YEAR_RANGE = /\A(\d{4})(?:-|\.\.)(\d{4})\Z/
  SONG_ORDER = ->(s){ [
		s.artist ? s.artist.downcase.sub(/\Athe /,'').gsub(/[^ _a-z0-9]+/,'') : "~~~~",
		s.album  || "~~~~",
		s.track  || 99,
		s.title ? s.title.downcase.sub(/\Athe /,'').gsub(/[^ _a-z0-9]+/,'') : "~~~~"
	]	}

	def initialize(args={})
		super()
		@mpd = MPD.new( args[:mpdhost], args[:mpdport] )
		@mpd.connect
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
		set :insecure_email_only_login, true
		$logger = Logger.new(STDOUT)
	end
end

require_relative 'routes/init'

