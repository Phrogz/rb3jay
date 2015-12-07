require ::File.join( ::File.dirname(__FILE__), 'app' )
run RB3Jay.new(
	mpdhost:'localhost',
	mpdport:6600,
	log:'rb3jay.log'
)