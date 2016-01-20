function Inspector(selector){
	this.$wrap = $(selector);
	this.$wrap.on('mouseenter','td',function(){
		var $this = $(this);
		if(this.offsetWidth<this.scrollWidth){
			if (!this.title) this.title = $this.text();
		} else if (this.title) this.title='';
	});
}

var songInfoTimer;
Inspector.prototype.inspect = function(file){
	this.$wrap[0].dataset.file = file;
	var song = songInfoByFile[file];
	updateSongInfo(song); // force updating of all the inspector cells

	// Now, let's make sure we have the latest details
	// Extra 200ms delay in case we're moving the selection quickly and won't really need latest info
	if (songInfoTimer) clearTimeout(songInfoTimer);
	songInfoTimer = setTimeout(function(){
		songInfoTimer = null;
		$.post('/checkdetails',{song:song,user:activeUser()});
	},200)
};
