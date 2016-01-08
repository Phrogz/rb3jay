class RB3Jay < Sinatra::Application
	get '/queue' do
		@mpd.queue(0..RB3Jay::MAX_RESULTS).map(&:details).to_json
	end
end