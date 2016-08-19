import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3
import QtQuick.Controls 1.4

ApplicationWindow {
    id: app
    minimumWidth: 600
    minimumHeight: 300
    visible: true
    width:1280; height:200
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

    function receiveUpNext(d){}
    function receivePlaylists(d){}
    function receiveSongInfo(d){}
    function logoutUser(){
        if (userSubscription) userSubscription.cancel();
        userSubscription = null;
        activeUser = null;
    }
    function loginUser(user){
        activeUser = user;
        var startup = server.subscribe('/startup-'+user, function(data){
            // øupnext.update(data.upnext);
            // øupnext.activeSong(data.status.file);
            // ømyqueue.updateQueue(data.myqueue);
            // øsongs.updatePlaylists(data.playlists);
            // øcontrols.update(data.status);
            // startup.cancel();
        });
        userSubscription = server.subscribe('/user-'+user,function(data){
            // if ('myqueue' in data) ømyqueue.updateQueue(data.myqueue);
            // if ('active'  in data) ømyqueue.updateActive(data.active);
        });
    }

    function post(path,data){
        if (!data) data = {};
        data.user = activeUser;
        var xhr = new XMLHttpRequest;
        xhr.onreadystatechange = function(){
            if (xhr.readyState==XMLHttpRequest.DONE){
                console.log("Post to ",path,"returned status",xhr.status,"and",xhr.responseText);
            }
        };
        xhr.open('POST',host+path);
        xhr.setRequestHeader('Content-Type', 'application/json;charset=UTF-8');
        xhr.send(JSON.stringify(data));
    }

    BayeuxClient {
        id: server
        url: host+'faye'
        Component.onCompleted: {
            subscribe('/status',      receiveStatus);
            subscribe('/next',        receiveUpNext);
            subscribe('/playlists',   receivePlaylists);
            subscribe('/songdetails', receiveSongInfo);
        }
    }

    SongDatabase { id:songdb }

    SplitView {
        orientation: Qt.Horizontal
        anchors { top:header.bottom; bottom:footer.top; left:parent.left; right:parent.right }
        SongList {
            id:songlist
            Layout.minimumWidth:200
        }
        SplitView {
            orientation: Qt.Vertical
            Layout.fillWidth:true
            MyQueue {
                id:myqueue
            }
            UpNext {
                id:upnext
            }
        }
    }

    menuBar: RowLayout {
        id: header
        spacing: 0
        height: 100
        width: parent.width
        PlayControl {
            id: playcontrol
            Layout.minimumWidth:200
            Layout.maximumWidth:200
            Layout.preferredWidth:200
            Layout.preferredHeight:parent.height
            Layout.fillHeight:true
            onPlayingFlagChanged: post(playingFlag ? '/play' : '/paws')
            onNext: post('skip')
        }
        SongControl {
            id: songcontrol
            Layout.minimumWidth: 200
            Layout.preferredWidth: parent.width*0.7
            Layout.preferredHeight:parent.height
            Layout.fillWidth:true
            Layout.fillHeight:true
        }
        AudioControl {
            id: audiocontrol
            Layout.minimumWidth: 200
            Layout.preferredWidth: parent.width*0.3
            Layout.fillWidth:true
            Layout.fillHeight:true
            Layout.preferredHeight:parent.height
        }
    }

    statusBar: Inspector {
        id: footer
        height:100
    }

}
