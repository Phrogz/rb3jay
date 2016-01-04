require ::File.join( ::File.dirname(__FILE__), 'app' )
run RB3Jay.new(
	mpd_host:         '127.0.0.1',
	mpd_port:         6600,
	mpd_sticker_file: '/Users/phrogz/.mpd/stickers.sql',
	log:              'rb3jay.log'
)