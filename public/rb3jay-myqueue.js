function MyQueue(selector){
	this.$tbody = $(selector);
	var tbody = this.$tbody[0];
	this.activeFlag = true;

	var $actions = $('#overflow-actions');
	$('#overflow-pieces')
		.on('mouseenter',function(){ $actions.fadeIn(50)   })
		.on('mouseleave',function(){ $actions.fadeOut(400) });
	$actions.on('click', $actions.trigger.bind($actions,'mouseleave'));

	$('#myqueue-shuffle').on('click',function(){
		$.post('/shuffle',{user:activeUser()});
	});
	$('#myqueue-toggle').on('click',(function(){
		this.makeActive( !this.activeFlag );
	}).bind(this));
	$('#myqueue-rollcall').on('click',function(){
		$.post('/rollcall',{user:activeUser()});
	});
	$('#myqueue-rescan').on('click',function(){
		$.post('/scan',{user:activeUser()});
	});

	this.selectSong = makeSelectable( this.$tbody );
	this.$tbody.on('songSelectionChanged',(function(evt,selectedFiles){
		if (this.onSelectionChanged) this.onSelectionChanged( selectedFiles );
	}).bind(this));
	this.$tbody.on('songDoubleClicked',(function(evt,selectedFiles){
		if (this.onDoubleClick) this.onDoubleClick( selectedFiles );
	}).bind(this));
	this.$tbody.on('deleteSongs',(function(evt,deletedFiles){
		this.removeSongs(deletedFiles);
		if (this.onDeleteSelection) this.onDeleteSelection(deletedFiles);
	}).bind(this));

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
		if (evt.stopPropagation) evt.stopPropagation();
		if (evt.preventDefault)  evt.preventDefault();
		self.appendSongs( evt.dataTransfer.getData('Text').split('∆≈ƒ') );
		return false;
	}, false );
}

MyQueue.prototype.updateQueue = function(songs){
	this.$tbody.empty();
	songs.forEach(function(song){
		songInfoByFile[song.file] = song; // TODO: don't overwrite richer data
		var $tr = $(songHTML(song))
		$tr.appendTo(this.$tbody);

		// Native HTML5 dragging
		var tr = $tr[0];
		tr.draggable = true;

		var self = this;
		tr.addEventListener( 'dragstart', function(evt){
			self.selectSong($(this),{ extend:evt.shiftKey, toggle:evt.ctrlKey || evt.metaKey });
			this.classList.add('drag');
			evt.dataTransfer.effectAllowed = 'move';
			evt.dataTransfer.setData( 'text', $tbody.find('tr.selected').map(function(){ return this.dataset.file }).toArray().join("∆≈ƒ") );
			return false;
		}, false );

		tr.addEventListener( 'dragend', function(evt){
			this.classList.remove('drag');
			return false;
		}, false );
	},this);
};

MyQueue.prototype.addSong = function(file,beforeIndex){
	var $tbody = this.$tbody;
	$tbody.find('tr[data-file="'+file+'"]').remove();

	var song = songInfoByFile[file];
	var $tr = $(songHTML(song));
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
		evt.dataTransfer.setData( 'text', $tbody.find('tr.selected').map(function(){ return this.dataset.file }).toArray().join("∆≈ƒ") );
		return false;
	}, false );

	tr.addEventListener( 'dragend', function(evt){
		this.classList.remove('drag');
		return false;
	}, false );
};

MyQueue.prototype.appendSongs = function(files,beforeIndex){
	files.forEach(function(file){
		this.addSong(file,beforeIndex);
	},this);
	$.post('/myqueue/add',{files:files,user:activeUser(),position:beforeIndex})
};

MyQueue.prototype.loadSong = function(song){
	if (!songInfoByFile[song.file]) songInfoByFile[song.file] = song;
	else for (var field in song) songInfoByFile[song.file][field] = song[field];
	this.addSong(song.file,null,true);
};

MyQueue.prototype.removeSongs = function(files){
	files.forEach(function(file){
		this.$tbody.find('tr[data-file="'+file+'"]').remove();
	},this);
	$.post('/myqueue/remove',{files:files,user:activeUser()})
};

MyQueue.prototype.updateActive = function(activeFlag){
	$('#myqueue-toggle').find('i')[0].className = 'fa fa-'+(activeFlag ? 'pause' : 'play');
	this.$tbody.toggleClass('paused',!activeFlag);
	this.activeFlag = activeFlag;
};

MyQueue.prototype.makeActive = function(active){
	$.post('/myqueue/'+(active ? 'active' : 'away'),{user:activeUser()});
};