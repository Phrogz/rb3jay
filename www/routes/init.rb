get '/' do
	haml :main
end

get '/search' do
  content_type :json
	rb3jay(cmd:"search", query:params[:query]).to_json
end

not_found do |*a|
  content_type :json
  halt 404, {
  	error:  'URL not found',
  	path:   request.path,
  	params: request.params
  }.to_json
end

helpers do
	def rb3jay(command)
		begin
			@socket.print(command.to_json)
		rescue NoMethodError, Errno::ECONNREFUSED
			@socket = TCPSocket.open(@rb3jayhost,@rb3jayport)
			sleep 0.02
			retry
		rescue Exception => e
			p errorwas:e
		end
		# JSON.parse(@socket.gets.chomp)
		(json=@socket.gets) && json.chomp!
		json = JSON.parse(json)
		json['ok'] ? json['result'] : json['msg']
	end
end