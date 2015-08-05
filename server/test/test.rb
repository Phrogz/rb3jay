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

		response = _query( cmd:"makePlaylist", name:"Party" )
		assert response['ok'], "Should be able to create a new playlist."

		lists = _query(cmd:"playlists")
		assert lists['ok'], "Should be able to ask for all playlists after creating"
		assert_equal 1, lists['result'].length, "Should have one playlist"
		party = lists['result'].first
		assert_equal "Party", party['name'], "Playlist should be named"
		assert_equal 0,       party['songs'], "Should have no songs"

		response = _query( cmd:"makePlaylist", name:"Party" )
		refute response['ok'], "Must not be able to create duplicate playlist with same name."

		response = _query( cmd:"makePlaylist", name:"Ambiance" )
		assert response['ok'], "Should be able to create a second playlist"

		lists = _query(cmd:"playlists")
		assert lists['ok'], "Still able to ask for all playlists"
		assert_equal 2, lists['result'].length, "Should have two playlists"
		lists = lists['result']
		assert_equal "Ambiance", lists[0]['name'], "Playlists should be sorted alphabetically"
		assert_equal "Party",    lists[1]['name'], "Playlists should be sorted alphabetically"
	end

	def test_playlist_editing
		response = _query( cmd:"makePlaylist", name:"Party" )
		assert response['ok'], "Should be able to create a new playlist."
		response = _query( cmd:"makePlaylist", name:"Ambiance" )
		assert response['ok'], "Should be able to create a second playlist"

		set1 = File.expand_path('../files/set1',__FILE__)
		response = _query(cmd:"scan", directory:set1)
		assert response['ok'], "Should be able to scan an existing directory"
		assert_kind_of Array, response['result'], "scan returns an array of songs found"
		assert_equal 4, response['result'].length, "should have found four songs"

		response = _query(cmd:"editPlaylist", name:"Party")
		assert response['ok'], "No-op edits are acceptable."

		response = _query(cmd:"editPlaylist", name:"Party", remove:[99,100])
		assert response['ok'], "Allowed to remove songs that don't exist."

		response = _query(cmd:"editPlaylist", name:"Party", add:[])
		assert response['ok'], "Allowed to add empty song list."

		response = _query(cmd:"playlist", name:"Party")
		assert response['ok'], "Can fetch playlist details."
		assert_equal 0, response['result']['songs'].length, "Adding empty songs does not modify list."

		song_id_by_file = _query(cmd:"songs")['result'].map do |song|
			[
				File.basename(_query(cmd:'song',id:song['id'])['result']['file']),
				song['id']
			]
		end.to_h
		party_ids = %w[BananaSlap.mp3 Slap.mp3 CoinDrops.mp3].map{|f| song_id_by_file[f]}
		response = _query(cmd:"editPlaylist", name:"Party", add:party_ids)
		assert response['ok'], "Adding songs should seem to work."

		response = _query(cmd:"playlist", name:"Party")
		assert response['ok']
		party = response['result']
		assert_equal 3, party['songs'].length, "Adding songs should actually work."
	end


	def test_songs
		response = _query(cmd:"songs")
		assert response['ok'], "Should be able to ask for all songs"
		assert_kind_of Array, response['result'], "songs should return an array"
		assert_equal 0, response['result'].length, "Should have no songs at first"

		response = _query(cmd:"scan", directory:'/doesnotexist/nononope')
		refute response['ok'], "Should error trying to scan an invalid directory"

		set1 = File.expand_path('../files/set1',__FILE__)
		response = _query(cmd:"scan", directory:set1)
		assert response['ok'], "Should be able to scan an existing directory"
		assert_kind_of Array, response['result'], "scan returns an array of songs found"
		assert_equal 4, response['result'].length, "should have found four songs"
		assert response['result'].any?{ |song| song['title']=='Banana Slap' }, "scanned songs should have metadata"

		response = _query(cmd:"scan", directory:set1)
		assert response['ok'], "Should be able to scan same directory again"
		assert_equal 0, response['result'].length, "should skip duplicate songs"

		response = _query(cmd:"songs")
		assert response['ok'], "Should be able to ask for all songs"
		assert_kind_of Array, response['result'], "songs should return an array"
		assert_equal 4, response['result'].length, "Should have four songs after scanning"
	end

	def test_search
		teardown
		setup( File.expand_path('../db1',__FILE__) )

		response = _query(cmd:"songs")
		assert response['ok'], "Should be able to ask for all songs"
		assert_kind_of Array, response['result'], "songs should return an array"
		assert_equal 4, response['result'].length, "Should have four songs loaded from DB"

		response = _query(cmd:"songs")
	end

	# ***************************************************************************

	def setup( directory=nil )
		cmd = "#{CMD} #{directory ? "-d #{directory}" : "-D"} --port #{PORT}#{' --debug' if $DEBUG}"
		puts "Test launching #{cmd.inspect}" if $DEBUG
		@pid = Process.spawn cmd
		begin
			@socket = TCPSocket.open('localhost', PORT)
		rescue Errno::ECONNREFUSED
			sleep 0.1
			retry
		end
	end

	def teardown
		if @socket && !@socket.closed?
			_send cmd:"quit"
			@socket.close
		end
		Process.kill( 'HUP', @pid )
	end

	def _send(data)
		puts "Test is sending: #{data.inspect}" if $DEBUG
		@socket.print(data.to_json)
	end

	def _query(data)
		_send(data)
		JSON.parse(@socket.gets.chomp).tap{ |x| puts "Test received #{x.inspect}" if $DEBUG }
	end
end
