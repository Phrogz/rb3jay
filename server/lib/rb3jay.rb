require 'eventmachine'
require 'time'
require 'json'

module RB3Jay
	VERSION = "0.0.1"
	def self.start( args )
		require_relative 'models/init'
		EventMachine.run do
			puts "rb3jay starting on port #{args[:port]}"
			EventMachine.start_server "127.0.0.1", args[:port], self
		end
		trap(:INT) { EventMachine.stop }
		trap(:HUP) { EventMachine.stop }
		trap(:TERM){ EventMachine.stop }
	end

	# ***************************************************************************

	def playlists
		Playlist.order(:name).all.map(&:summary)
	end

	def makePlaylist(name:, code:nil)
		Playlist.create(name:name, query:code, created:Time.now.utc.iso8601)
		"Created playlist #{name}"
	end

	def quit
		puts "rb3jay shutting down..."
		EventMachine.stop
		nil
	end

	# ***************************************************************************

	def receive_data(data)
		data.chomp!
		begin
			puts "rb3jay received: #{data}" if ARGS[:debug]
			req = JSON.parse(data)
			return err! "Queries must be JSON Objects" unless req.is_a? Hash
			return err! "No cmd supplied" unless req['cmd']
			cmd = req.delete('cmd').to_s
			return err! "Unsupported cmd #{cmd.inspect}" unless respond_to? cmd
			begin
				opts = Hash[ req.map{ |k,v| [k.to_sym,v] } ]
				result = method(cmd).parameters.empty? ? send(cmd) : send(cmd,opts)
				joy! result unless result.nil?
			rescue Exception => e
				err! "Problem running #{cmd.inspect}", {message:e.message}
			end
		rescue JSON::ParserError => e
			err! "Could not parse: #{data.inspect}", {message:e.message}
		end
	end

	def joy!(result)
		send! ok:true, result:result
	end

	def err!(msg,details=nil)
		result = { ok:false, msg:msg }
		unless details.nil?
			details = {details:details} unless details.is_a? Hash
			result.merge! details
		end
		send! result
	end

	def send!(data)
		puts "rb3jay sending: #{data.to_json}" if ARGS[:debug]
		send_data( data.to_json + "\n" )
	end

end

