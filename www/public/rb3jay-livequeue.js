function LiveQueue(selector){
	this.$tbody = $(selector);
	this.selectSong = makeSelectable( this.$tbody, true );
	this.$tbody.on('songSelectionChanged',(function(evt,selectedFiles){
		if (this.onSelectionChanged) this.onSelectionChanged( selectedFiles );
	}).bind(this));
	this.fileByIndex = [];
	$.get('/next',this.update.bind(this));
}

LiveQueue.prototype.update = function(songs){
	console.log('LiveQueue update');
	if (songs.nochange) return;
	var newFiles = songs.map(function(s){ return s.file });
	var oldFiles = this.$tbody.find('tr').map(function(){ return this.dataset.file }).toArray();
	if (arraysEqual(newFiles,oldFiles)) return; // don't rebuild the HTML if it will be the same
	this.$tbody.empty();
	songs.forEach((function(song,i){
		this.fileByIndex[i] = song.file;
		øinspector.songInfo(song.file,song);
		var $tr = $(øinspector.songHTML(song.file)).appendTo(this.$tbody);
		if (i==this.activeIndex) $tr.addClass('active');
	}).bind(this));
};

LiveQueue.prototype.activeSongIndex = function(songIndex){
	var file = this.fileByIndex[ songIndex ];
	var active = this.$tbody.find('tr').eq(songIndex);
	if (!active.hasClass('active')){
		this.$tbody.find('tr.active').removeClass('active');
		this.$tbody.find('tr:eq('+songIndex+')').addClass('active');
	}
	this.activeIndex = songIndex;
	return øinspector.songInfo(file);
};