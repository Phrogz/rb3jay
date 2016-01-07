SongList = (function(){
	var SELECTED_CLASS = 'selected';
	var FOCUSED_CLASS  = 'focused';

	function SongList(listSelector,searchSelector,clearSelector){
		this.$tbody = $(listSelector);
		this.$inp   = $(searchSelector);
		this.$clear = $(clearSelector);
		var self = this;
		this.selectSong = makeSelectable( this.$tbody );
		this.$tbody.on('songSelectionChanged',function(evt,selectedFiles){
			if (self.onSelectionChanged) self.onSelectionChanged( selectedFiles );
		});
		this.$tbody.on('songDoubleClicked',function(evt,selectedFiles){
			if (self.onDoubleClick) self.onDoubleClick( selectedFiles );
		});

		var self = this;
		var form = this.$inp.closest('form');
		this.$inp.bindDelayed({
			url:'/search',
			data:function(){ return form.serialize() },
			callback:this.load,
			callbackScope:this,
			resendDuplicates:false
		});
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
		øinspector.songInfo(song.file,song);
		var $tr = $(øinspector.songHTML(song.file)).appendTo(this.$tbody);

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
			this.classList.remove('drag');
			return false;
		}, false );
	};

	return SongList;
})();