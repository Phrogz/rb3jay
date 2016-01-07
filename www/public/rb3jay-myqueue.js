function MyQueue(selector){
	this.$tbody = $(selector);
	var tbody = this.$tbody[0],
      self  = this;

	this.selectSong = makeSelectable( this.$tbody );
	this.$tbody.on('songSelectionChanged',function(evt,selectedSongIds){
		if (self.onSelectionChanged) self.onSelectionChanged( selectedSongIds );
	});
	this.$tbody.on('songDoubleClicked',function(evt,selectedSongIds){
		if (self.onDoubleClick) self.onDoubleClick( selectedSongIds );
	});
	this.$tbody.on('deleteSongs',function(evt,deletedSongIds){
		self.removeSongs(deletedSongIds);
		if (self.onDeleteSelection) self.onDeleteSelection(deletedSongIds);
	});

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

	tbody.addEventListener( 'drop', function(evt) {
		this.classList.remove('over');
		if (evt.stopPropagation) evt.stopPropagation(); // Stops some browsers from redirecting.
		evt.dataTransfer.getData('Text').split('∆≈ƒ').forEach(self.appendSong,self);
		return false;
	}, false );

}

MyQueue.prototype.addSong = function(songId,beforeIndex) {
	var $tbody = this.$tbody;

	$tbody.find('tr[data-songid="'+songId+'"]').remove();
	var $tr = $(øinspector.songHTML(songId));
	if (beforeIndex==null) $tr.appendTo($tbody);
	else                   $tr.insertBefore( $tbody.find('tr:eq('+beforeIndex+')') )

	// Native HTML5 dragging
	var tr = $tr[0];
	tr.draggable = true;

	var self = this;
	tr.addEventListener( 'dragstart', function(evt){
		self.selectSong($(this),{ extend:evt.shiftKey, toggle:evt.ctrlKey || evt.metaKey });
		this.classList.add('drag');
		evt.dataTransfer.effectAllowed = 'move';
		evt.dataTransfer.setData( 'text', $tbody.find('tr.selected').map(function(){ return this.dataset.songid }).toArray().join("∆≈ƒ") );
		return false;
	}, false );

	tr.addEventListener( 'dragend', function(evt){
		this.classList.remove('drag');
		return false;
	}, false );

	// TODO: inform the server
};

MyQueue.prototype.appendSong = function(songId){
	this.addSong(songId);
};

MyQueue.prototype.removeSongs = function(songIds){
	songIds.forEach(function(songId){
		this.$tbody.find('tr[data-songid="'+songId+'"]').remove();
		// TODO: inform the server
	},this);
};