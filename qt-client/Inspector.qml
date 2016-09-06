import QtQuick 2.7

Rectangle {
	id: root
	color:ɢtheme.inspector.backColor
	width:parent.width
	height:ɢtheme.inspector.height

	property string file
	property QtObject øsong: file ? ɢsongdb.fromFile(file) : undefined

	InspectorLabel { rc:[0,0]; text:'title' }
	InspectorField { rc:[0,0]; value:øsong && øsong.title }

	InspectorLabel { rc:[0,1]; text:'artist' }
	InspectorField { rc:[0,1]; value:øsong && øsong.artist }

	InspectorLabel { rc:[0,2]; text:'album' }
	InspectorField { rc:[0,2]; value:øsong && øsong.album }

	// -----------------------------------------

	InspectorLabel { rc:[1,0]; text:'genre' }
	InspectorField { rc:[1,0]; value:øsong && øsong.genre }

	InspectorLabel { rc:[1,1]; text:'composer' }
	InspectorField { rc:[1,1]; value:øsong && øsong.composer }

	InspectorLabel { rc:[1,2]; text:'year' }
	InspectorField { rc:[1,2]; value:øsong && øsong.year || null }

	// -----------------------------------------

	InspectorLabel { rc:[2,0]; text:'my rating' }
	InspectorField { rc:[2,0]; content: Rating { song:øsong } }

	InspectorLabel { rc:[2,1]; text:'score'     }
	InspectorField { rc:[2,1]; value:øsong && øsong.score }

	InspectorLabel { rc:[2,2]; text:'length' }
	InspectorField { rc:[2,2]; value:øsong && øsong.time && duration(øsong.time) }

	// -----------------------------------------

	InspectorLabel { rc:[3,0]; text:'played' }
	InspectorField { rc:[3,0];
		value:øsong && øsong.played && (øsong.played+'× ('+timeSince(øsong.lastPlayed)+')')
	}

	InspectorLabel { rc:[3,1]; text:'skipped' }
	InspectorField { rc:[3,1];
		value:øsong && øsong.skipped && (øsong.skipped+'× ('+timeSince(øsong.lastSkipped)+')')
	}

	InspectorLabel { rc:[3,2]; text:'file' }
	InspectorField { rc:[3,2];
		value:øsong && øsong.file
		elide:Text.ElideMiddle
	}

	// http://stackoverflow.com/a/23259289/405017
	function timeSince(date) {
		if (typeof date !== 'object') date = new Date(date);
		var seconds = Math.floor((new Date - date) / 1000);
		var interval = Math.floor(seconds / 31536000);
		if (interval >= 1) return pack('year');
		interval = Math.floor(seconds / 2592000);
		if (interval >= 1) return pack('month');
		interval = Math.floor(seconds / 86400);
		if (interval >= 1) return pack('day');
		interval = Math.floor(seconds / 3600);
		if (interval >= 1) return pack('hour');
		interval = Math.floor(seconds / 60);
		if (interval >= 1) return pack('minute');
		interval = seconds;
		return pack('second');
		function pack(type){ return interval+' '+type+(interval==1 ? '' : 's')+' ago' }
	}

	function duration(seconds){
		if (isNaN(seconds)) return '-';
		var hours   = Math.floor(seconds/3600);
		var minutes = Math.floor(seconds/60%60);
		seconds     = Math.round(seconds % 60);
		if (seconds<10) seconds = "0"+seconds;
		if (hours>=1){
			if (minutes<10) minutes = "0"+minutes;
			return hours+":"+minutes+":"+seconds;
		}else{
			return minutes+":"+seconds;
		}
	}
}
