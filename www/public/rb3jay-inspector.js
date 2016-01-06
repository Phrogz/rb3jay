Inspector = (function(){
	var fieldMap = {
		title   : "title",
		genre   : "genre",
		rating  : "rating",
		added   : "added",
		artist  : "artist",
		year    : "year",
		score   : "score",
		played  : "played",
		album   : "album",
		length  : function(s){ return duration(s.time) },
		file    : "file",
		skipped : "skipped",
	};

	var songHTMLById = {};
	var songInfoById = {};

	function Inspector(selector){
		this.$wrap = $(selector);
	}

	Inspector.prototype.inspect = function(songId){
		var song = songId ? songInfoById[songId] : {};
		for (var field in fieldMap){
			var value = fieldMap[field];
			if (typeof value==='string') value = song[field] || "-";
			else                         value = value(song);
			this.$wrap.find('#ins-'+field).html(value);
		}
	};

	Inspector.prototype.songHTML = function(songId) {
		var html = songHTMLById[songId];
		if (!html){
			var song = this.songInfo( songId );
			html = songHTMLById[songId] = '<tr data-songid="'+song.id+'"><td>'+song.title+'</td><td>'+song.artist+'</td></tr>';
		}
		return html;
	};

	Inspector.prototype.songInfo = function(songId,song) {
		if (song) songInfoById[songId] = song;
		else{
			song = songInfoById[songId];
			if (!song){
				// TODO: synchronous fetch?
				console.log('Error: RB3Jay wanted information about '+songId+' but could not find it.');
				song = { title:"NO TITLE", artist:"NO ARTIST", time:0 };
			}
			return song;
		}
	};

	return Inspector;
})();