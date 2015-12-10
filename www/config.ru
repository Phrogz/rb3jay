require ::File.join( ::File.dirname(__FILE__), 'app' )
run RB3Jay.new(
	mpdhost:        'localhost',
	mpdport:        6600,
	mpdstickerfile: '/Users/phrogz/.config/mpd/sticker.sql',
	log:            'rb3jay.log'
)