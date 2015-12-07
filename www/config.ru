require ::File.join( ::File.dirname(__FILE__), 'app' )
run RB3JayWWW.new(
	rb3jayhost: 'localhost',
	rb3jayport: 7331,
	log:     'rb3jay-www.log'
)