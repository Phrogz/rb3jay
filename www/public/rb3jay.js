var songInfoById = {};

var øcontrols  = new Controls('#playing'),
    øsongs     = new SongList('#songlist tbody','#search-input','#search-clear'),
    øqueue     = new MyQueue('#myqueue tbody'),
    ølive      = new LiveQueue('#livequeue tbody');
    øinspector = new Inspector('#inspector');

øsongs.onSelectionChanged = function(songId){
	øinspector.inspect(songId);
};

function duration(seconds){
	if (isNaN(seconds)) return '-';
	var hours   = Math.floor(seconds/3600);
	var minutes = Math.floor((seconds%3600)/60);
	seconds = Math.round(seconds % 60);
	if (seconds<10) seconds = "0"+seconds;
	if (hours>=1){
		if (minutes<10) minutes = "0"+minutes;
		return hours+":"+minutes+":"+seconds;
	}else{
		return minutes+":"+seconds;
	}
}

