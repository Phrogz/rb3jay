var songInfoById = {};

var øcontrols  = new Controls('#playing'),
    øsongs     = new SongList('#songlist tbody','#search-input','#search-clear'),
    øqueue     = new MyQueue('#myqueue tbody'),
    ølive      = new LiveQueue('#livequeue tbody');
    øinspector = new Inspector('#inspector');

øsongs.onSelectionChanged = function(files){ øinspector.inspect(files[0]) };
øsongs.onDoubleClick      = function(files){ files.forEach( øqueue.appendSong, øqueue ) };
øqueue.onSelectionChanged = function(files){ øinspector.inspect(files[0]) };
øqueue.onDeleteSelection  = function(files){ øinspector.inspect() };
ølive.onSelectionChanged  = function(files){ øinspector.inspect(files[0]) };

checkLogin();

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

function makeSelectable($tbody){
	var FOCUSED  = 'focused',
	    SELECTED = 'selected';
	$tbody.on('click','tr',function($evt){
		// TODO: OS X should not use control key for toggle; Windows should not use metaKey for toggle
		_select( $(this), { extend:$evt.shiftKey, toggle:$evt.metaKey || $evt.ctrlKey } );
		$tbody.trigger( 'songSelectionChanged', [_selectedFiles()] );
	}).on('dblclick','tr',function(){
		_select( $(this), {} );
		$tbody.trigger( 'songDoubleClicked', [_selectedFiles()] );
	});

	var table = $tbody.closest('table')[0];
	$(document.body).on('keydown',function(evt){
		// TODO: test on Safari; perhaps use :focus with jQuery instead
		if (document.activeElement==table){
			if (evt.keyCode==46) $tbody.trigger( 'deleteSongs', [_selectedFiles()] );
		}
	});

	return _select;

	function _selectedFiles(){
		return $tbody.find('tr.'+SELECTED).map(function(){ return this.dataset.file }).toArray();
	}

	var $selectionStart;
	function _select($tr,opts){
		if (!opts) opts={};
		if (opts.toggle) $tr.toggleClass(SELECTED);
		else if (opts.extend && $selectionStart){
			var a = $selectionStart.index();
			var b = $tr.index();
			if (a<b) $tbody.find('tr').slice(a+1,b+1).addClass(SELECTED);
			else     $tbody.find('tr').slice(b,a).addClass(SELECTED);
			document.getSelection().removeAllRanges(); // shift-clicking tends to select text on the page; deselect it
		} else if (!$tr.hasClass(SELECTED)){
			$tbody.find('tr.'+SELECTED).removeClass(SELECTED);
			$tr.addClass(SELECTED);
			$selectionStart = $tr;
		}
	}
}

function checkLogin(){
	$('#login').on('submit',function(evt){
		if (this.elements.user.value){
			activeUser(this.elements.user.value);
			$('#login').hide();
			checkLogin();
		}
		evt.preventDefault();
		return false;
	});
	$('#logout').on('click',function(evt){
		Cookies.remove('username');
		checkLogin();
	});
	var user = activeUser();
	if (!user) $('#login').show();
	else{
		$('#myqueue caption').contents().first().replaceWith( user+"'s queue " );
		$.get('/myqueue',{user:user},function(playlist){
			playlist.songs.forEach(function(song){
				øinspector.songInfo(song.file,song);
				øqueue.loadSong(song.file);
			})
		});
	}
}

function activeUser(username){
	if (username) Cookies.set('username',username,{expires:365});
	else return Cookies.get('username');
}