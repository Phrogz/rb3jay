function LiveQueue(selector){
	this.$tbody = $(selector);
	var self = this;
	this.selectSong = makeSelectable( this.$tbody );
	this.$tbody.on('songSelectionChanged',function(evt,selectedFiles){
		if (self.onSelectionChanged) self.onSelectionChanged( selectedFiles );
	});

	this.reload();
}

LiveQueue.prototype.reload = function(){
	var $tbody = this.$tbody;
	$.get('/queue',function(songs){
		$tbody.empty();
		songs.forEach(function(song){
			øinspector.songInfo(song.file,song);
			$(øinspector.songHTML(song.file)).appendTo($tbody);
		});
	});
};