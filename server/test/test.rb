require 'socket'
require 'json'
require 'minitest/unit'

PORT = 7336
CMD = File.expand_path("../../bin/rb3jay",__FILE__)

class TestServer < MiniTest::Unit::TestCase
  def setup
    @thread = Thread.new{ `#{CMD} -D --port #{PORT}` }
    sleep 0.5
    @socket = TCPSocket.open('localhost', PORT)
    STDOUT.puts "hi mom"
  end

  def teardown
  	@socket.close if @socket
  	@thread.kill  if @thread
  end

  def send(data)
  	@socket.print(data.to_json)
  	JSON.parse @socket.gets.chomp
  end

  def test_bad_commands
    refute_nil @thread
    refute_nil @socket
    assert_false send(false)['ok'],    "Missing command should cleanly fail."
    assert_false send(cmd:"no")['ok'], "Unrecognized command should cleanly fail."
  end
end

runner = MiniTest::Unit.new
t = TestServer.new( runner )
p :setup
t.setup
p :testbad
t.test_bad_commands
p :teardown
t.teardown

