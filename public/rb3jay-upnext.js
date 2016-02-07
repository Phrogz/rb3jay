function UpNext(selector){
	this.$tbody = $(selector);
	this.selectSong = makeSelectable( this.$tbody, true );
	this.$tbody.on('songSelectionChanged',(function(evt,selectedFiles){
		if (this.onSelectionChanged) this.onSelectionChanged( selectedFiles );
	}).bind(this));
}

UpNext.prototype.update = function(songs){
	var selectedFile = this.$tbody.find('tr.selected')[0];
	selectedFile = selectedFile && selectedFile.dataset.file;

	this.$tbody.empty();
	songs.done.forEach((function(song){
		if (!songInfoByFile[song.file]) $.post('/checkdetails',{song:song});
		var $tr = $(songHTML(song)).appendTo(this.$tbody);
		$tr.addClass('played');
		if (song.priority) $tr.addClass('priority');
		if (song.user) $tr.addClass( 'user-'+song.user );
	}).bind(this));

	songs.next.forEach((function(song){
		if (!songInfoByFile[song.file]) songInfoByFile[song.file] = song;
		var $tr = $(songHTML(song)).appendTo(this.$tbody);
		if (song.file==this.lastActive) $tr.addClass('active');
		if (song.priority) $tr.addClass('priority');
		if (song.user) $tr.addClass( 'user-'+song.user );
	}).bind(this));

	var $rowToSelect;
	if (selectedFile) $rowToSelect = this.$tbody.find( 'tr[data-file="'+selectedFile+'"]' );
	if (!($rowToSelect && $rowToSelect[0])) $rowToSelect = this.$tbody.find( 'tr.active' );
	if ($rowToSelect[0]){
		øinspector.inspect( $rowToSelect[0].dataset.file );
		this.selectSong( $rowToSelect );
	}
};

UpNext.prototype.activeSong = function(file){
	if (file == this.lastActive) return;
	this.lastActive = file;
	this.$tbody.find('tr.active').removeClass('active');
	var $active = this.$tbody.find('tr[data-file="'+file+'"]').addClass('active');
	if (!this.$tbody.find('tr.selected')[0]) this.selectSong($active,{inspect:true});
};