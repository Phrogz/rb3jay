import QtQml 2.2
import QtQuick 2.7
import QtWebSockets 1.0

Item {
	// Number of seconds to wait for a connection before retrying; set to 0 to prevent retries
	property real retry: 2

	// Will automatically connect to the server once url is set
	property string url: ''

	property string øclientId: ''
	property var    øqueue: []
	property var    øcalls: ({})
	property var    øpaths: ({})
	property string østatus: ''

	onUrlChanged: if (url) øconnect();

	function subscribe( channel, callback ){
		var parts = /^(.*?)(\/\*{1,2})?$/.exec(channel);
		var base=parts[1], wild=parts[2];
		if (!øcalls[base]) øcalls[base]=[];
		var index = øcalls[base].length;
		øcalls[base].push({callback:callback,wild:wild});
		publish('/meta/subscribe',{subscription:channel});
		return { cancel:function(){ øcalls[base].splice(index,1) } };
	}

	function publish( channel, data, options ){
		if (!options) options={};
		var message = { channel:channel };
		Object.keys(data).forEach(function(key){ message[key]=data[key] });
		øqueue[options.beforeOthers ? 'unshift' : 'push'](message);
		øprocessQueue();
	}

	function øconnect(){
		if (østatus=='connecting') return;
		console.log('attempting to connect',new Date);
		østatus = 'connecting';
		if (retry) delayedRetryConnect.start();
		var xhr = new XMLHttpRequest;
		xhr.onreadystatechange = function(){
			if (xhr.readyState==XMLHttpRequest.DONE){
				if (xhr.status==200) øhandleMessage(xhr.responseText);
				else østatus='';
			}
		};
		xhr.open('POST',url);
		xhr.setRequestHeader('Content-Type', 'application/json;charset=UTF-8');
		xhr.send(JSON.stringify([{
			channel:'/meta/handshake', version:'1.0',
			supportedConnectionTypes:['websocket','long-polling']
		}]));
	}

	function øhandleMessage( message ){
		if (!message) return;
		if ("string"===typeof message) message = JSON.parse(message);
		if (message instanceof Array) return message.forEach(øhandleMessage);

		// TODO: handle advice field for any message

		if(message.channel=="/meta/handshake"){
			console.assert(message.successful,"TODO: handle unsuccessful handshake");
			if (message.successful){
				øclientId  = message.clientId;
				østatus = 'connected';
				if (~message.supportedConnectionTypes.indexOf('websocket')){
					if (socket.url) socket.url = ''; // reset the socket
					socket.url = url.replace( /^(?:\w+:\/\/)/, 'ws://' );
				} else console.error("TODO: BayeuxClient currently only supports websocket communication");
				publish('/meta/connect',{connectionType:'websocket'},{beforeOthers:true});
			} else østatus='';
		} else {
			if (!øpaths[message.channel]){
				var parts = message.channel.split('/');
				øpaths[message.channel] = parts.map(function(_,i){ return parts.slice(0,i+1).join('/') }).reverse();
			}
			øpaths[message.channel].forEach(function(path,index){
				if (øcalls[path]) øcalls[path].forEach(function(o){
					if ( (index==0) || (index==1 && o.wild) || (o.wild=='/**') ) o.callback(message.data);
				});
			});
		}
	}

	function øprocessQueue(){
		if (socket.status==WebSocket.Open){
			øqueue.forEach(function(message){
				message.clientId = øclientId;
				socket.sendTextMessage(JSON.stringify(message));
			});
			øqueue.length=0;
		} else if (socket.status!=WebSocket.Connecting) øconnect();
	}

	WebSocket {
		id: socket
		onStatusChanged: {
			if (!socket) return; // Happens when the app is shutting down
			switch(socket.status){
				case WebSocket.Open: øprocessQueue(); break;
				case WebSocket.Error: console.log("websocket error:", socket.errorString); break;
			}
		}
		Component.onCompleted: textMessageReceived.connect(øhandleMessage);
	}

	Timer {
		id: delayedRetryConnect
		interval: 1000*retry
		onTriggered: if (!østatus) øconnect();
	}
}
