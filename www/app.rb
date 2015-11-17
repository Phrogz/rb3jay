# encoding: utf-8

SERVER_ADDRESS = "bugbot"
SERVER_PORT    = 80

Dir.chdir( File.dirname( __FILE__ ) )
require 'sinatra'
require 'haml'
require 'logger'
require 'ruby-mpd'
require 'json'
# require_relative 'minify_resources'

class RB3JayWWW < Sinatra::Application
	use Rack::Session::Cookie, key:'rb3jaywww.session', path:'/', secret:'znogood'
	def initialize(args={})
		super()
		@mpd = args[:mpdhost] ? (args[:mpdport] ? MPD.new(args[:mpdhost], args[:mpdport]) : MPD.new(args[:mpdhost])) : MPD.new
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

