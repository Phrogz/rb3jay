require ::File.join( ::File.dirname(__FILE__), 'app' )
run RB3JayWWW.new(
	mpdhost: 'localhost',
	mpdport: 6600,
	log:     'rb3jay-www.log'
)