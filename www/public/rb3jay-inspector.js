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

	return Inspector;
})();