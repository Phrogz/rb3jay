angular.module('rb3jay', [])
.controller('App', function(){
	this.load = function(a,b,c){
		console.log(a);
		console.log(b);
		console.log(c);
		console.log(this);
	}
})
.controller('Playlists', function(){
	this.all = [
		{ name:"Female Vocals" },
		{ name:"ZZNap" }
	];
});
