function UpNext(selector){
	this.$tbody = $(selector);
	this.selectSong = makeSelectable( this.$tbody, true );
	this.$tbody.on('songSelectionChanged',(function(evt,selectedFiles){
		if (this.onSelectionChanged) this.onSelectionChanged( selectedFiles );
	}).bind(this));
	$.get('/next',this.update.bind(this));

	var tbody = this.$tbody[0];
	tbody.addEventListener( 'dragenter', function(evt){
		this.classList.add('over');
		return false;
	}, false );

	tbody.addEventListener( 'dragover', function(evt){
		evt.dataTransfer.dropEffect = 'copy';
		if (evt.preventDefault) evt.preventDefault();
		this.classList.add('over');
		return false;
	}, false );

	tbody.addEventListener( 'dragleave', function(evt){
		this.classList.remove('over');
		return false;
	}, false );

	var self = this;
	tbody.addEventListener( 'drop', function(evt) {
		this.classList.remove('over');
		if (evt.stopPropagation) evt.stopPropagation(); // Stops some browsers from redirecting.
		self.appendSongs( evt.dataTransfer.getData('Text').split('∆≈ƒ') );
		return false;
	}, false );

}

UpNext.prototype.update = function(songs){
	var newFiles = songs.map(function(s){ return s.file });
	var oldFiles = this.$tbody.find('tr').map(function(){ return this.dataset.file }).toArray();
	if (arraysEqual(newFiles,oldFiles)) return; // don't rebuild the HTML if it will be the same

	var selectedFile = this.$tbody.find('tr.selected')[0];
	selectedFile = selectedFile && selectedFile.dataset.file;

	this.$tbody.empty();
	songs.forEach((function(song,i){
		if (!songInfoByFile[song.file]) songInfoByFile[song.file] = song;
		var $tr = $(songHTML(song)).appendTo(this.$tbody);
		if (song.file==this.lastActive) $tr.addClass('active');
		if (song.priority) $tr.addClass('priority');
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

UpNext.prototype.appendSongs = function(songs){
	$.post('/qadd',{songs:songs,priority:1,user:activeUser()});
};