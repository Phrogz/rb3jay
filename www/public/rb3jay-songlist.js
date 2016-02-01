SongList = (function(){
	var SELECTED_CLASS = 'selected';
	var FOCUSED_CLASS  = 'focused';

	function SongList(listSelector,searchSelector,clearSelector){
		this.$tbody = $(listSelector);
		this.$inp   = $(searchSelector);
		this.$clear = $(clearSelector);
		this.selectSong = makeSelectable( this.$tbody );

		this.$tbody.on('songSelectionChanged',(function(evt,selectedFiles){
			if (this.onSelectionChanged) this.onSelectionChanged( selectedFiles );
		}).bind(this));
		this.$tbody.on('songDoubleClicked',(function(evt,selectedFiles){
			if (this.onDoubleClick) this.onDoubleClick( selectedFiles );
		}).bind(this));

		this.$playlists = $('select[name="playlist"]')
		.on('change',(function(){ this.$inp.trigger('keyup') }).bind(this) );

		var form = this.$inp.closest('form');
		this.$inp.bindDelayed({
			url:'/search',
			delay:200,
			data:function(){ return form.serialize() },
			callback:this.load.bind(this),
			resendDuplicates:false
		}).trigger('keyup');
	}

	SongList.prototype.load = function(songsArray){
		this.clear();
		this.songs = songsArray;
		songsArray.forEach(this.addSong,this);
	};

	SongList.prototype.clear = function(){
		this.$tbody.empty();
	};

	SongList.prototype.addSong = function(song){
		if (!song || !song.file) return;
		if (!songInfoByFile[song.file]) songInfoByFile[song.file] = song;
		var $tr = $(songHTML(song)).appendTo(this.$tbody);

		// Native HTML5 dragging
		var tr = $tr[0];
		tr.draggable = true;

		var self = this;
		var tbody = this.$tbody;
		tr.addEventListener( 'dragstart', function(evt){
			self.selectSong($(this));
			this.classList.add('drag');
			evt.dataTransfer.effectAllowed = 'copy';
			evt.dataTransfer.setData( 'text', tbody.find('tr.selected').map(function(){ return this.dataset.file }).toArray().join("∆≈ƒ") );
			return false;
		}, false );

		tr.addEventListener( 'dragend', function(evt){
			if (evt.preventDefault) evt.preventDefault();
			this.classList.remove('drag');
			return false;
		}, false );
	};

	SongList.prototype.updatePlaylists = function(playlists){
		var $select = this.$playlists;
		$select[0].options.length=1; // Leave the "(all songs)" entry
		playlists.forEach(function(name){ $select.append(new Option(name)) });
	};

	return SongList;
})();