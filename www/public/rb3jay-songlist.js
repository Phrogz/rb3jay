SongList = (function(){
	var SELECTED_CLASS = 'selected';

	function SongList(listSelector,searchSelector,clearSelector){
		this.$tbody = $(listSelector);
		this.$inp   = $(searchSelector);
		this.$clear = $(clearSelector);
		var self = this;
		this.$tbody.on('click','tr',function(evt){
			self.select( $(this), { extend:evt.shiftKey, toggle:evt.metaKey } );
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
		this.rows = [];
	};

	SongList.prototype.addSong = function(song){
		songInfoById[song.id] = song;
		var $tr = $('<tr id="'+song.id+'"><td>'+song.title+'</td><td>'+song.artist+'</td></tr>')
		$tr.appendTo(this.$tbody);
		this.rows.push($tr);

		// Native HTML5 dragging
		var tr = $tr[0];
		tr.draggable = true;

		var self = this;
		var tbody = this.$tbody;
		tr.addEventListener( 'dragstart', function(evt){
			self.select($(this));
			this.classList.add('drag');
			evt.dataTransfer.effectAllowed = 'copy';
			evt.dataTransfer.setData( 'text', tbody.find('tr.selected').map(function(){ return this.id }).toArray().join("∆≈ƒ") );
			return false;
		}, false );

		tr.addEventListener( 'dragend', function(evt){
			this.classList.remove('drag');
			return false;
		}, false );
	};

	var $selectionStart;
	SongList.prototype.select = function($tr,opts){
		if (!opts) $tr.addClass(SELECTED_CLASS);
		else if (opts.extend && $selectionStart){
			var a = $selectionStart.index();
			var b = $tr.index();
			if (a<b) for (var i=a+1;i<=b;++i) this.select(this.rows[i]);
			else     for (var i=a-1;i>=b;--i) this.select(this.rows[i]);
			document.getSelection().removeAllRanges();
		}else if (opts.toggle){
			if ($tr.hasClass(SELECTED_CLASS)) $tr.removeClass(SELECTED_CLASS);
			else this.select($tr);
		}else{
			this.$tbody.find('tr.'+SELECTED_CLASS).removeClass(SELECTED_CLASS);
			this.select($tr);
			$selectionStart = $tr;
		}
		if (this.onSelectionChanged) this.onSelectionChanged(this.$tbody.find('tr.'+SELECTED_CLASS).attr('id'));
	};

	return SongList;
})();