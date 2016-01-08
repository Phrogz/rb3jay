function Controls(wrapSelector){
	this.$wrap = $(wrapSelector);
	this.playing = false;
	this.volume	 = 75;
	this.$progress  = this.$wrap.find('#progress');
	this.$elapsed   = this.$wrap.find('#elapsed');
	this.$remaining = this.$wrap.find('#remaining');
	this.$title     = this.$wrap.find('#title');
	this.$artalb    = this.$wrap.find('#artalb');

	this.$toggle = this.$wrap.find('#toggle').on('click',(function(){
		if (!this.lastStatus) return;
		var action = this.lastStatus.state=='play' ? '/pause' : '/play';
		$.post(action,this.update.bind(this));
	}).bind(this));

	this.$wrap.find('#next').on('click',(function(){
		$.post('/next',this.update.bind(this));
	}).bind(this));

	this.$volume = this.$wrap.find('#volume input')
	.on('input',     function(){ $.post('/volume',{volume:this.value})  })
	.on('mouseenter',function(){ $(this).on('mousewheel',volumeWheel)   })
	.on('mouseexit', function(){ $(this).off('mousewheel',volumeWheel)  });
	function volumeWheel($evt){ this.value = this.value*1 + $evt.deltaY*2; $(this).trigger('input') }

	var self = this;
	this.$slider = this.$progress.find('input').on('input',function(){
		var desiredTime = self.lastStatus.time[1] * this.value/100;
		$.post('/seek', {time:desiredTime}, updateControls.bind(self) );
	});

	setInterval(this.refresh.bind(this),1000);
	this.refresh();
}

Controls.prototype.refresh = function(){
	$.get('/status',updateControls.bind(this));
};

Controls.prototype.update = function(){
	ølive.refresh();
	this.refresh();
};

function updateControls(status){
	var playPause = { play:'fa fa-pause', pause:'fa fa-play', stop:'fa fa-play' };
	this.lastStatus = status;
	this.$wrap.find('#progress').css('visibility',status.time?'':'hidden');
	if (status.time){
		this.$slider.val( 100*status.elapsed/status.time[1] );
		this.$elapsed.html( duration(status.elapsed) );
		this.$remaining.html( duration(status.time[1]-status.time[0]) );
	}
	this.$volume.val( status.volume );
	var song = ølive && ølive.activeSongIndex( status.song );
	this.$toggle.find('i')[0].className = playPause[status.state];
	if (song){
		this.$title.html( song.title );
		var artalb = [];
		if (song.artist) artalb.push(song.artist);
		if (song.album)  artalb.push(song.album);
		this.$artalb.html( artalb.join(" — ") );
	}else{
		this.$title.html("");
		this.$artalb.html("(no song playing)");
	}
}