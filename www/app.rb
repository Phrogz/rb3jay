# encoding: utf-8

SERVER_ADDRESS = "bugbot"
SERVER_PORT    = 80

Dir.chdir( File.dirname( __FILE__ ) )
require 'sinatra'
require 'sequel'
require 'moneta'
require 'rack/session/moneta'
require 'logger'
require 'json'
require 'ruby-mpd'

# require_relative 'minify_resources'

require_relative 'helpers/init'
require_relative 'routes/init'

class RB3Jay < Sinatra::Application
	use Rack::Session::Moneta, key:'rb3jay.session', path:'/', store: :LRUHash

	MAX_RESULTS = 500

	def initialize(args={})
		super()
		args[:mpd_host] ||= ENV['MPD_HOST'] || '127.0.0.1'
		args[:mpd_port] ||= ENV['MPD_PORT'] || 6600
		args[:mpd_sticker_file] ||= ENV['MPD_STICKER_FILE']
		@mpd = MPD.new( args[:mpd_host], args[:mpd_port] )
		@mpd.connect
		require_relative 'model/init'
		@db = connect_to( args[:mpd_sticker_file] )
	end

	before{ content_type :json }

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


