PORT = 7331
cmd = File.expand_path("../../bin/rb3jay",__FILE__)

Thread.new{ `#{cmd} -D -p #{PORT}` }

require 'socket'
require 'json'

TCPSocket.open('localhost', PORT) do |socket|
	socket.print({cmd:"echo",opts:"hello world"}.to_json)
	p socket.gets
end