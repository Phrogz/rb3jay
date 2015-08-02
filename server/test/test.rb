require 'socket'
require 'json'
require 'minitest/autorun'

PORT = 7331
CMD = File.expand_path("../../bin/rb3jay",__FILE__)

class TestServer < MiniTest::Unit::TestCase
	def test_bad_commands
		refute _query(false)['ok'],    "Missing command should cleanly fail."
		refute _query(cmd:"no")['ok'], "Unrecognized command should cleanly fail."
	end

	def test_playlists
		existing = _query(cmd:"playlists")
		assert existing['ok'], "Should be able to ask for all playlists"
		assert_kind_of Array, existing['result'], "playlists should return an array"
		assert_equal 0, existing['result'].length, "Should start with no playlists"

		result = _query( cmd:"makePlaylist", name:"Party" )
		assert result['ok'], "Should be able to create a new playlist."

		lists = _query(cmd:"playlists")
		assert lists['ok'], "Should be able to ask for all playlists after creating"
		assert_equal 1, lists['result'].length, "Should have one playlist"
		party = lists['result'].first
		assert_equal "Party", party['name'], "Playlist should be named"
		assert_equal 0,       party['songs'], "Should have no songs"

		result = _query( cmd:"makePlaylist", name:"Party" )
		refute result['ok'], "Must not be able to create duplicate playlist with same name."

		result = _query( cmd:"makePlaylist", name:"Ambience" )
		assert result['ok'], "Should be able to create a second playlist."
	end

	# ***************************************************************************

	def setup
		_create
	end

	def teardown
		_destroy
	end

	def _create( directory=nil )
		cmd = "#{CMD} #{directory ? "-d #{directory}" : "-D"} #{'--debug' if $DEBUG} --port #{PORT}"
		puts "Test launching #{cmd.inspect}" if $DEBUG
		@pid = Process.spawn cmd
		begin
			@socket = TCPSocket.open('localhost', PORT)
		rescue Errno::ECONNREFUSED
			sleep 0.1
			retry
		end
	end

	def _destroy
		if @socket && !@socket.closed?
			_send cmd:"quit"
			@socket.close
		end
		Process.kill( 'HUP', @pid )
	end

	def _send(data)
		puts "Test is sending: #{data.inspect}" if $DEBUG
		@socket.puts(data.to_json)
	end

	def _query(data)
		_send(data)
		JSON.parse(@socket.gets.chomp).tap{ |x| puts "Test received #{x.inspect}" if $DEBUG }
	end
end
