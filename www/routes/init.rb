get '/' do
	haml :main
end

not_found do |*a|
  content_type :json
  halt 404, {
  	error:  'URL not found',
  	path:   request.path,
  	params: request.params
  }.to_json
end
