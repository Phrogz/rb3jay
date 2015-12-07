(function($){
	var app = angular.module('rb3jay', []);

	app.factory('Share', function(){
		return {selectedSongs:[]};
	});

	app.controller('PlaybackController', ['$scope','Share',function($scope,Share){
		this.playing = false;
		this.volume  = 75;
		this.song    = { id:723, title:"Hello", artist:"Adele", album:"???", duration:347 };

		var elapsed=0,elapsedPct=0,remaining=0;
		Object.defineProperties(this,{
			elapsed:{
				get:function( ){ return elapsed },
				set:function(v){ elapsedPercent=100*(elapsed=v)/this.song.duration }
			},
			elapsedPercent:{
				get:function( ){ return elapsedPct },
				set:function(v){ elapsed=(elapsedPct=v)*this.song.duration/100 }
			},
			remaining:{
				get:function( ){ return this.song.duration-this.elapsed },
				set:function(v){ this.elapsed = this.song.duration-v }
			}
		});

		this.toggle = function(){
			this.playing = !this.playing;
			console.log('TODO: send toggle to server');
		};

		this.nextSong = function(){
			console.log('TODO: send nextSong to server');
		};
	}]);

	app.controller('SongsController', ['$scope','Share',function($scope,Share){
		var ss = Share.selectedSongs;
		var selectStart;
		this.select = function(song,evt){
			if (evt){
				if (evt.shiftKey && selectStart){
					var a = this.found.indexOf(selectStart);
					var b  = this.found.indexOf(song);
					if (a<b) for (var i=a+1;i<=b;++i) this.select(this.found[i]);
					else     for (var i=a-1;i>=b;--i) this.select(this.found[i]);
					document.getSelection().removeAllRanges();
				}else if (evt.metaKey){
					if (song.selected){
						song.selected = false;
						for (var i=ss.length;--i;) if (ss[i]==song) ss.splice(i,1);
						// Share.inspect();
					}	else this.select(song);
				}else{
					ss.forEach(function(s){ s.selected=false });
					ss.length = 0;
					selectStart = null;
					this.select(song);
				}
			} else {
				song.selected = true;
				ss.push(song);
				selectStart = song;
				Share.inspect(song);
			}
		};
		var self = this;
		this.found = [];
		var searchForm = $('#search-form');
		$('#search-input').bindDelayed({
			url:'/search',
			data:function(){ return searchForm.serialize() },
			callback:function(songs){
				$scope.$apply(function(){ self.found=songs });
			},
			resendDuplicates:false
		});
	}]);

	app.controller('InspectorController', ['$scope','Share',function($scope,Share){
		this.ss = Share.ss;
		inspector = this;
		Share.inspect = this.inspectSong = function(song){
			if (song)	for (var field in song) inspector[field] = song[field];
			else      for (var field in inspector) inspector[field] = null;
		};
	}]);

	app.controller('MyQueueController', function(){
		this.visible = [
			{ name:"Female Vocals" },
			{ name:"ZZNap" }
		];
	});

	app.controller('LiveQueueController', function(){
		this.visible = [
			{ name:"Female Vocals" },
			{ name:"ZZNap" }
		];
	});

	app.filter('duration', function(){
		return function(seconds){
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
		};
	});

	// http://blog.parkji.co.uk/2013/08/11/native-drag-and-drop-in-angularjs.html
	app.directive('draggable', function(){
		return function(scope, element) {
			var el = element[0]; // the native DOM object
			el.draggable = true;

			el.addEventListener( 'dragstart', function(evt){
				evt.dataTransfer.effectAllowed = 'copy';
				evt.dataTransfer.setData('Text', this.id);
				this.classList.add('drag');
				return false;
			}, false );

			el.addEventListener( 'dragend', function(evt){
				this.classList.remove('drag');
				return false;
			}, false );
		}
	});

	app.directive('droppable', function(){ return {
		scope: {},
		link: function(scope, element){
			var el = element[0]; // the native DOM object

			el.addEventListener( 'dragover', function(evt){
				evt.dataTransfer.dropEffect = 'copy';
				if (evt.preventDefault) evt.preventDefault();
				this.classList.add('over');
				return false;
			}, false );

			el.addEventListener( 'dragenter', function(evt){
				this.classList.add('over');
				return false;
			}, false );

			el.addEventListener( 'dragleave', function(evt){
				this.classList.remove('over');
				return false;
			}, false );

			el.addEventListener( 'drop', function(evt) {
				if (evt.stopPropagation) evt.stopPropagation(); // Stops some browsers from redirecting.
				var item = document.getElementById(evt.dataTransfer.getData('Text'));
				this.appendChild(item.cloneNode(true));

				this.classList.remove('over');
				return false;
			}, false );
		}
	} });

})(jQuery);