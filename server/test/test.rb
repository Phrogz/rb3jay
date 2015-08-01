require 'socket'
require 'json'
require 'minitest/autorun'

PORT = 7331
CMD = File.expand_path("../../bin/rb3jay",__FILE__)

class TestServer < MiniTest::Unit::TestCase
	def setup
		@pid = Process.spawn "#{CMD} -D --port #{PORT}"
		begin
			@socket = TCPSocket.open('localhost', PORT)
		rescue Errno::ECONNREFUSED
			sleep 0.1
			retry
		end
	end

	def teardown
		if @socket && !@socket.closed?
			@socket.puts({cmd:"quit"}.to_json)
			@socket.close
		end
		Process.kill( 'HUP', @pid )
	end

	def tell(data)
		@socket.puts(data.to_json)
		JSON.parse @socket.gets.chomp
	end

	def test_bad_commands
		refute tell(false)['ok'],    "Missing command should cleanly fail."
		refute tell(cmd:"no")['ok'], "Unrecognized command should cleanly fail."
	end
end
