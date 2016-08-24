import QtQml 2.2

QtObject {
	id: songdb
	property var songsByFile: ({})
	property Component songObj: Component {
		QtObject {
			id:song
			property string file
			property string title
			property string artist
			property string album
			property string albumartist
			property string genre
			property string composer
			property int    time
			property int    date
			property real   score
			property date   lastPlayed: new Date
			property int    played
			property int    skipped
			property int    disc
			property date   infoUpdated
			property string event
			property int    priority
			property string user
			property var    ratings: ({})

			function toJSON(){
				var o = {file:file};
				var fields = ['title','artist','album','time','priority',
					'modified','track','genre','date','composer','disc',
					'albumartist','bpm','artwork','ratings','played','skipped'];
				fields.forEach(function(f){ if (song[f]) o[f]=song[f] });
				if (!isNaN(lastPlayed)) o.lastplayed = lastPlayed*1; // ms since epoch
				return o;
			}

			function update(details){
				Object.keys(details).forEach(function(k){
					if ((k in song) && details[k]!==null) song[k]=details[k];
				});
			}
		}
	}

	function fromFile(file,details){
		var song = songsByFile[file];
		if (!song) song = songsByFile[file] = songObj.createObject(songdb,{file:file});
		if (details) song.update(details);
		return song;
	}

//	// Do not pass along user, or else automated re-inspection will keep the user active
//	if (!songsByFile[file].title) ɢapp.post('/checkdetails',{song:song.toJSON(),user:null});

	function update(details){
		return fromFile(details.file,details);
	}
}
