function Controls(wrapSelector){
	this.$wrap = $(wrapSelector);
	this.$progress  = this.$wrap.find('#progress');
	this.$elapsed   = this.$wrap.find('#elapsed');
	this.$remaining = this.$wrap.find('#remaining');
	this.$song      = this.$wrap.find('#song');
	this.$title     = this.$wrap.find('.song-title');
	this.$artalb    = this.$wrap.find('.song-artalb');
	this.rating     = this.$wrap.find('.song-rating')[0];

	var self = this;

	$(document.body).on('keydown',function(evt){
		if (document.activeElement==self.rating){
			switch(evt.keyCode){
				case 40: //down arrow
					_modifyRating(-1);
				break;
				case 38: //up arrow
					_modifyRating(+1);
				break;
			}
		}
	});

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
		// Wait a second after updating before allowing status updates to change volume.
		// Stops the slider from jumping back and forth when dragging or rolling.
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

	function _modifyRating(offset){
		$.post('/adjust-active-song-rating',{user:activeUser(),change:offset});
	}
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
	this.$toggle.find('i')[0].className = playPause[status.state];
	if (status.file == this.lastFile) return;
	this.lastFile = status.file;
	if (status.file){
		this.$song[0].dataset.file = status.file;
		var song = songInfoByFile[status.file]
		updateSongInfo(song);
		var desiredTitle = "3J: "+[song.title,song.artist].join(" — ");
		if (document.title!=desiredTitle) document.title = desiredTitle;
	}else{
		this.$title.html("");
		this.$artalb.html("(no song playing)");
		this.rating.className = 'song-rating'; // removes any extra classes
	}
};
