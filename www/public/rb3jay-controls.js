function Controls(wrapSelector){
	this.$wrap = $(wrapSelector);
	this.$progress  = this.$wrap.find('#progress');
	this.$elapsed   = this.$wrap.find('#elapsed');
	this.$remaining = this.$wrap.find('#remaining');
	this.$title     = this.$wrap.find('#title');
	this.$artalb    = this.$wrap.find('#artalb');

	var self = this;

	this.$toggle = this.$wrap.find('#toggle').on('click',(function(){
		if (!this.lastStatus) return;
		var action = this.lastStatus.state=='play' ? '/paws' : '/play';
		$.post(action);
	}).bind(this));

	this.$wrap.find('#next').on('click',function(){
		$.post('/skip');
	});

	this.$volume = this.$wrap.find('#volume input')
	.on('input', function(){
		$.post('/volm',{volume:this.value});
		// Wait a second after updating before allowing status updates to change volume
		// Stops the slider from jumping back and forth when dragging or rolling
		self.nextVolumeUpdate = (new Date).getTime() + 1000;
	})
	.on('mousewheel', function($evt){
		this.value = this.value*1 + $evt.deltaY*1;
		$(this).trigger('input');
	});

	this.$slider = this.$progress.find('input').on('input',function(){
		var desiredTime = self.lastStatus.time[1] * this.value;
		self.nextSeekUpdate = (new Date).getTime() + 1000;
		$.post('/seek', {time:desiredTime} );
	});
}

Controls.prototype.update = function(status){
	var playPause = { play:'fa fa-pause', pause:'fa fa-play', stop:'fa fa-play' };
	this.lastStatus = status;
	this.$wrap.find('#progress').css('visibility',status.time?'':'hidden');
	if (status.time){
		if (!this.nextSeekUpdate || (new Date).getTime() >= this.nextSeekUpdate){
			this.$slider.val( status.elapsed/status.time[1] );
		}
		this.$elapsed.html( duration(status.elapsed) );
		this.$remaining.html( duration(status.time[1]-status.time[0]) );
	}
	if (!this.nextVolumeUpdate || (new Date).getTime() >= this.nextVolumeUpdate){
		this.$volume.val( status.volume );
	}
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
};