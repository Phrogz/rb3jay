function MyQueue(selector){
	this.$tbody = $(selector);
	var tbody = this.$tbody[0];

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
		if (evt.stopPropagation) evt.stopPropagation(); // Stops some browsers from redirecting.
		evt.dataTransfer.getData('Text').split('∆≈ƒ').forEach(self.appendSong,self);
		return false;
	}, false );
}

MyQueue.prototype.addSong = function(file,beforeIndex,viewOnly) {
	var $tbody = this.$tbody;

	$tbody.find('tr[data-file="'+file+'"]').remove();
	var $tr = $(øinspector.songHTML(file));
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

	if (!viewOnly) $.post('/myqueue/add',{file:file,user:activeUser(),position:beforeIndex})
};

MyQueue.prototype.appendSong = function(file){
	this.addSong(file);
};

MyQueue.prototype.loadSong = function(file){
	this.addSong(file,null,true);
};

MyQueue.prototype.removeSongs = function(files){
	files.forEach(function(file){
		this.$tbody.find('tr[data-file="'+file+'"]').remove();
		$.post('/myqueue/remove',{file:file,user:activeUser()})
	},this);
};