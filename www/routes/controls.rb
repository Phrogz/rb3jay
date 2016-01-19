class RB3Jay < Sinatra::Application
	get '/' do
		content_type :html
		send_file File.expand_path('rb3jay.html',settings.public_folder)
	end

	get '/status' do
		@mpd.status.to_json
	end

	post '/play' do
		@mpd.play
		'"now playing"'
	end

	post '/pause' do
		@mpd.pause = true
		'"paused"'
	end

	post '/next' do
		@mpd.next
		@mpd.status.to_json
	end

	post '/seek' do
		@mpd.seek params[:time].to_f
		@mpd.status.to_json
	end

	post '/volume' do
		@mpd.volume = params[:volume].to_i
	end

	not_found do |*a|
		halt 404, {
			error:  'URL not found',
			path:   request.path,
			params: request.params
	}.to_json
	end
end