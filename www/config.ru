require ::File.join( ::File.dirname(__FILE__), 'app' )
run RB3Jay.new(
	mpd_sticker_file: '/var/lib/mpd/sticker.sql',
	log:              'rb3jay.log'
)