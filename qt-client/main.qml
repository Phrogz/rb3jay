import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3
import QtQuick.Controls 1.4

ApplicationWindow {
	id: ɢapp
	minimumWidth: 600
	minimumHeight: 300
	visible: true
	width:1280; height:500
	title: "RB3Jay"

	property string host: 'http://localhost:8080/'
	property string activeUser

	property var userSubscription

	function receiveStatus(s){
		playcontrol.playingFlag = s.state=="play";
		songcontrol.song        = s.file;
		songcontrol.elapsed     = s.elapsed;
		songcontrol.duration    = s.time && s.time[1];
		audiocontrol.volume     = s.volume;
	}

	function receivePlaylists(d){}
	function logoutUser(){
		if (userSubscription) userSubscription.cancel();
		userSubscription = null;
		activeUser = null;
	}
	function loginUser(user){
		activeUser = user;
		var startup = server.subscribe('/startup-'+user, function(data){
			upnext.update(data.upnext);
			// øupnext.activeSong(data.status.file);
			// ømyqueue.updateMyQueue(data.myqueue);
			// øsongs.updatePlaylists(data.playlists);
			// øcontrols.update(data.status);
			startup.cancel();
		});
		userSubscription = server.subscribe('/user-'+user,function(data){
			if ('myqueue' in data) updateMyQueue(data.myqueue);
			if ('active'  in data) updateActive(data.active);
		});
	}

	function post(path,data,callback){
		xhr('POST',path,data,callback);
	}

	function get(path,data,callback){
		xhr('GET',path,data,callback);
	}

	function xhr(method,path,data,callback){
		if (!data) data={};
		if (data.user!==null) data.user=activeUser;
		else delete data.user;

		var xhr = new XMLHttpRequest;
		xhr.onreadystatechange = function(){
			if (xhr.readyState==XMLHttpRequest.DONE){
//				console.log(method+" to ",path,"returned status",xhr.status,"and",JSON.stringify(xhr.responseText));
				if (xhr.status==200 && callback) callback(JSON.parse(xhr.responseText));
			}
		};
		xhr.open(method,host+path);
		xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

		var kv=[], add=function(k,v){ kv[kv.length]=encodeURIComponent(k)+"="+encodeURIComponent(v) };
		for (var k in data) buildParams(k,data[k],add);
		xhr.send(kv.join("&").replace(/%20/g,"+"));
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
			subscribe('/status',      receiveStatus);
			subscribe('/next',        upnext.update);
			subscribe('/playlists',   receivePlaylists);
			subscribe('/songdetails', ɢsongdb.update);
		}
	}

	SongDatabase { id:ɢsongdb }
	Theme        { id:ɢtheme  }

	Component.onCompleted: {
		loginUser('gkistner');
	}

	SplitView {
		orientation: Qt.Horizontal
		anchors.fill: parent
		SongList {
			id:songlist
			Layout.minimumWidth:200
			Layout.fillWidth:true
			Layout.preferredWidth:ɢapp.width/2
		}
		SplitView {
			orientation: Qt.Vertical
			Layout.minimumWidth:200
			Layout.preferredWidth:ɢapp.width/2
			MyQueue {
				id:myqueue
				Layout.minimumHeight: ɢtheme.titlebarHeight + ɢtheme.songHeight
				Layout.fillWidth:true
			}
			UpNext {
				id:upnext
				Layout.minimumHeight: ɢtheme.titlebarHeight + ɢtheme.songHeight
				Layout.fillWidth:true
			}
		}
	}

	toolBar: Rectangle {
		color: ɢtheme.headerBGColor
		height: ɢtheme.headerHeight
		width: parent.width
		RowLayout {
			anchors.fill: parent
			spacing: 0
			PlayControl {
				id: playcontrol
				Layout.minimumWidth:2*ɢtheme.headerHeight
				Layout.maximumWidth:2*ɢtheme.headerHeight
				Layout.preferredWidth:2*ɢtheme.headerHeight
				Layout.preferredHeight:parent.height
				Layout.fillHeight:true
				onPlayingFlagChanged: post(playingFlag ? '/play' : '/paws')
				onNext: post('skip')
			}
			SongControl {
				id: songcontrol
				Layout.minimumWidth: 2*ɢtheme.headerHeight
				Layout.preferredWidth: parent.width*0.7
				Layout.preferredHeight:parent.height
				Layout.fillWidth:true
				Layout.fillHeight:true
			}
			AudioControl {
				id: audiocontrol
				Layout.minimumWidth: 2*ɢtheme.headerHeight
				Layout.preferredWidth: parent.width*0.3
				Layout.fillWidth:true
				Layout.fillHeight:true
				Layout.preferredHeight:parent.height
			}
		}
	}

	statusBar: Inspector {
		id: footer
		height:ɢtheme.inspectorHeight
	}
}
