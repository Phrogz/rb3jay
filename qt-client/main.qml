import QtQuick 2.7
import QtQuick.Layouts 1.3
import QtQuick.Controls 1.4

ApplicationWindow {
	id: ɢapp
	visible: true
	minimumWidth:600; minimumHeight:300
	width:1000; height:400
	title: "RB3Jay"

	property string host: 'http://localhost:8080/'
	property string ɢactiveUser

	property var øuserSubscription

	function receivePlaylists(d){}

	function logoutUser(){
		if (øuserSubscription) øuserSubscription.cancel();
		øuserSubscription = null;
		ɢactiveUser = null;
	}

	function loginUser(user){
		ɢactiveUser = user;
		var startup = server.subscribe('/startup-'+user, function(data){
			header.update(data.status);
			upnext.update(data.upnext);
			myqueue.update(data.myqueue);
			// songlist.updatePlaylists(data.playlists);
			startup.cancel();
		});
		øuserSubscription = server.subscribe('/user-'+user,function(data){
			if ('myqueue' in data) myqueue.update(data.myqueue);
			if ('active'  in data) myqueue.active = data.active;
		});
		songlist.getSongs();
	}

	function buildParams( key, val, add ) {
		if (val instanceof Array){
			val.forEach(function(v,i){
				if (/\[\]$/.test(key)) add(key,v);
				else if (typeof v==='object' || v instanceof Array) buildParams(key+'['+i+']',v);
				else buildParams(key+'[]',v,add);
			});
		} else if (val!=null && typeof val === "object"){
			for (var k in val) buildParams(key+'['+k+']',val[k],add);
		} else add(key,val);
	}

	BayeuxClient {
		id: server
		// debug: true
		url: host+'faye'
		Component.onCompleted: {
			subscribe('/status',      header.update);
			subscribe('/next',        upnext.update);
			// subscribe('/playlists',   songlist.updatePlaylists);
			subscribe('/songdetails', ɢsongdb.update);
		}
	}

	SongDatabase { id:ɢsongdb }
	Theme        { id:ɢtheme  }

	Component.onCompleted: loginUser('phrogz');

	SplitView {
		orientation: Qt.Horizontal
		anchors.fill: parent
		SongList {
			id:songlist
			Layout.minimumWidth:200
			Layout.fillWidth:true
			width:ɢapp.width/2
		}
		SplitView {
			orientation: Qt.Vertical
			Layout.minimumWidth:200
			width:songlist.width
			MyQueue {
				id:myqueue
				Layout.minimumHeight: ɢtheme.titlebars.height + ɢtheme.songs.height*1.5
				Layout.fillWidth:true
				height:(ɢapp.height-header.height-ɢinspector.height)/2
			}
			UpNext {
				id:upnext
				Layout.minimumHeight: ɢtheme.titlebars.height + ɢtheme.songs.height*1.5
				Layout.fillWidth:true
				height:myqueue.height
			}
		}
	}

	toolBar:   Header { id:header }
	statusBar: Inspector { id: ɢinspector }

	function post(path,data,callback){ xhr('POST',path,data,callback) }
	function get( path,data,callback){ xhr('GET', path,data,callback) }
	function xhr(method,path,data,callback){
		if (!data) data={};
		if (data.user!==null) data.user=ɢactiveUser;
		else delete data.user;

		var xhr = new XMLHttpRequest;
		xhr.onreadystatechange = function(){
			if (xhr.readyState==XMLHttpRequest.DONE && xhr.status==200 && callback)
				callback(JSON.parse(xhr.responseText));
		};
		var kv=[], add=function(k,v){ kv[kv.length]=encodeURIComponent(k)+"="+encodeURIComponent(v) };
		for (var k in data) buildParams(k,data[k],add);
		data = kv.join("&").replace(/%20/g,"+");
		if (method=='GET'){
			xhr.open(method,host+path+'?'+data);
			xhr.send();
		} else {
			xhr.open(method,host+path);
			xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
			xhr.send();
		}
	}

	function formatDuration(seconds) {
		if (isNaN(seconds)) return '-';
		var hors = Math.floor(seconds / 3600);
		var mins = Math.floor(seconds / 60 % 60);
		seconds = Math.round(seconds % 60);
		if (seconds < 10) seconds = "0" + seconds;
		if (hors) return hors + ":" + (mins < 10 ? '0' : '') + mins + ":" + seconds
		else      return mins + ":" + seconds
	}

}
