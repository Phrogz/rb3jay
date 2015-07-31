require 'eventmachine'
require 'json'

module RB3Jay
	VERSION = "0.0.1"
	def self.start( args )
		require_relative 'models/init'
		EventMachine.run do
			EventMachine.start_server "127.0.0.1", args[:port], self
		end
	end

	def receive_data(data)
		data.chomp!
		begin
			puts "Received: #{data}" if ARGS[:debug]
			req = JSON.parse(data)
			return err! "No cmd supplied" unless req['cmd']
			cmd = req['cmd'].to_s
			return err! "Unsupported cmd #{cmd.inspect}" unless respond_to? cmd
			begin
				joy! method(cmd).arity==0 ? send(cmd) : send(cmd,req['opts'])
			rescue Exception => e
				err! "Problem running #{cmd.inspect}", e
			end
		rescue JSON::ParserError => e
			err! "Could not parse: #{data.inspect}", e
		end
	end

	def joy!(result)
		send! {ok:true, result:result}.to_json
	end

	def err!(msg,details=nil)
		result = { ok:false, msg:msg }
		result.merge!( details:details ) unless details.nil?
		send! result
	end

	def send!(data)
		puts "Sending: #{data.to_json}" if ARGS[:debug]
		send_data( data.to_json + "\n" )
	end

	# ***************************************************************************

	def quit
		puts "rb3jay shutting down..."
		EventMachine.stop
	end

end

