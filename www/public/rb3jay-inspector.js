Inspector = (function(){
	var fieldMap = {
		title   : "title",
		genre   : "genre",
		rating  : "rating",
		composer: "composer",
		artist  : "artist",
		year    : "year",
		score   : "score",
		played  : "played",
		album   : "album",
		length  : function(s){ return duration(s.time) },
		file    : "file",
		skipped : "skipped",
	};

	var songHTMLByFile = {};
	var songInfoByFile = {};

	function Inspector(selector){
		this.$wrap = $(selector);
		this.$wrap.on('mouseenter','td',function(){
	    var $this = $(this);
			if(this.offsetWidth<this.scrollWidth){
				if (!this.title) this.title = $this.text();
			} else if (this.title) this.title='';
		});
	}

	Inspector.prototype.inspect = function(file){
		var song = file ? songInfoByFile[file] : {};
		for (var field in fieldMap){
			var value = fieldMap[field];
			if (typeof value==='string') value = song[field] || "-";
			else                         value = value(song);
			this.$wrap.find('#ins-'+field).html(value);
		}
	};

	Inspector.prototype.songHTML = function(file) {
		var html = songHTMLByFile[file];
		if (!html){
			var song = this.songInfo( file );
			html = songHTMLByFile[file] = '<tr data-file="'+song.file+'"><td>'+song.title+'</td><td>'+song.artist+'</td></tr>';
		}
		return html;
	};

	Inspector.prototype.songInfo = function(file,song) {
		if (!file) return;
		if (song) songInfoByFile[file] = song;
		else{
			song = songInfoByFile[file];
			if (!song){
				// TODO: synchronous fetch?
				console.log('Error: RB3Jay wanted information about '+file+' but could not find it.');
				song = { title:"NO TITLE", artist:"NO ARTIST", time:0 };
			}
			return song;
		}
	};

	return Inspector;
})();