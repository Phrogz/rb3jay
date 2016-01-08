function LiveQueue(selector){
	this.$tbody = $(selector);
	this.selectSong = makeSelectable( this.$tbody, true );
	this.$tbody.on('songSelectionChanged',(function(evt,selectedFiles){
		if (this.onSelectionChanged) this.onSelectionChanged( selectedFiles );
	}).bind(this));
	this.fileByIndex = [];
	setInterval( this.refresh.bind(this), 2000 );
	this.refresh();
}

LiveQueue.prototype.refresh = function(){
	var $tbody = this.$tbody;
	$.get('/queue',(function(songs){
		var newFiles = songs.map(function(s){ return s.file });
		var oldFiles = this.$tbody.find('tr').map(function(){ return this.dataset.file }).toArray();
		if (arraysEqual(newFiles,oldFiles)) return; // don't rebuild the HTML if it will be the same
		$tbody.empty();
		songs.forEach((function(song,i){
			this.fileByIndex[i] = song.file;
			øinspector.songInfo(song.file,song);
			var $tr = $(øinspector.songHTML(song.file)).appendTo($tbody);
			if (i==this.activeIndex) $tr.addClass('active');
		}).bind(this));
	}).bind(this));
};

LiveQueue.prototype.activeSongIndex = function(songIndex){
	var file = this.fileByIndex[ songIndex ];
	this.$tbody.find('tr.active').removeClass('active');
	this.$tbody.find('tr:eq('+songIndex+')').addClass('active');
	this.activeIndex = songIndex;
	return øinspector.songInfo(file);
};