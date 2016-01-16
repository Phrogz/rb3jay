var songInfoById = {};

var øserver    = new Faye.Client('/faye', { retry:2, timeout:10 } ),
    øcontrols  = new Controls('#playing'),
    øsongs     = new SongList('#songlist tbody','#search-input','#search-clear'),
    øqueue     = new MyQueue('#myqueue tbody'),
    ølive      = new LiveQueue('#livequeue tbody'),
    øinspector = new Inspector('#inspector');

øsongs.onDoubleClick      = function(files){ øqueue.appendSongs(files) };
øqueue.onDeleteSelection  = function(files){ øinspector.inspect() };

øsongs.onSelectionChanged = function(files){ øinspector.inspect(files[0]) };
øqueue.onSelectionChanged = function(files){ øinspector.inspect(files[0]) };
ølive.onSelectionChanged  = function(files){ øinspector.inspect(files[0]) };

øserver.subscribe('/status',    øcontrols.update.bind(øcontrols)   );
øserver.subscribe('/next',      ølive.update.bind(ølive)           );
øserver.subscribe('/playlists', øsongs.updatePlaylists.bind(øsongs));

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

function makeSelectable($tbody,singleSelectOnly){
	var FOCUSED  = 'focused',
	    SELECTED = 'selected';
	$tbody.on('click','tr',function($evt){
		// TODO: OS X should not use control key for toggle; Windows should not use metaKey for toggle
		_select( $(this), { extend:!singleSelectOnly && $evt.shiftKey, toggle:!singleSelectOnly && ($evt.metaKey || $evt.ctrlKey) } );
		$tbody.trigger( 'songSelectionChanged', [_selectedFiles()] );
	}).on('dblclick','tr',function(){
		_select( $(this), {} );
		$tbody.trigger( 'songDoubleClicked', [_selectedFiles()] );
	}).on('mouseenter','td',function(){
    var $this = $(this);
		if(this.offsetWidth<this.scrollWidth){
			if (!this.title) this.title = $this.text();
		} else if (this.title) this.title='';
	});

	var table = $tbody.closest('table')[0];
	$(document.body).on('keydown',function(evt){
		// TODO: test on Safari; perhaps use :focus with jQuery instead
		if (document.activeElement==table){
			switch(evt.keyCode){
				case 46: // del
					$tbody.trigger( 'deleteSongs', [_selectedFiles()] );
				break;
				case 40: //down arrow
					_modifySelection(1,evt.shiftKey);
				break;
				case 38: //up arrow
					_modifySelection(-1,evt.shiftKey);
				break;
				// default:
				// 	console.log(table.id,evt.keyCode);
			}
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
		} else if (!$tr.hasClass(SELECTED)){
			$tbody.find('tr.'+SELECTED).removeClass(SELECTED);
			$tr.addClass(SELECTED);
			$selectionStart = $tr;
		}
		document.getSelection().removeAllRanges(); // shift-clicking and double-clicking tends to select text on the page; deselect it
	}

	function _modifySelection(offset,extendSelection){
		var $rows = $tbody.find('tr');
		var $end  = $tbody.find('tr.'+SELECTED)[offset>1 ? 'last' : 'first']();
		var nextIndex = $end.index() + offset;

		var $next = $rows.eq(nextIndex<0 ? undefined : nextIndex);
		if ($next[0]){
			_select($next,{extend:!singleSelectOnly && extendSelection});
			$tbody.trigger( 'songSelectionChanged', [_selectedFiles()] );
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

function arraysEqual(a,b){
	return (a.length === b.length) && a.every(function(v,i){ return v === b[i] });
}