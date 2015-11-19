require ::File.join( ::File.dirname(__FILE__), 'app' )
run RB3JayWWW.new(
	mpdhost: ENV['MPD_HOST'] || 'localhost',
	mpdport: ENV['MPD_PORT'] || 6600,
	log:     'rb3jay-www.log'
)