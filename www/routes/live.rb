class RB3Jay < Sinatra::Application
	get '/queue' do
		json = @mpd.queue(0..RB3Jay::MAX_RESULTS).map(&:details).to_json
		if json!=session[:lastqueue] || params[:force]
			session[:lastqueue] = json
		else
			'{"nochange":1}'
		end
	end
end