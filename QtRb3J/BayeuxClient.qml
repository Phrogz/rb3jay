import QtQml 2.2
import QtQuick 2.7
import QtWebSockets 1.0

Item {
	id: root

	// Number of seconds to wait for a connection before retrying; set to 0 to prevent retries
	property real   retry: 2
	property string url: ''

	property string _clientId: ''
	property var    _queue: []
	property var    _calls: ({})
	property var    _paths: ({})
	property bool   _connected: false

	property var    _socketStatus: ({})

	onUrlChanged: if (url) connect();

	function connect(){
		console.log("Attempting to connect to ",url);
		if (retry) delayedRetryConnect.start();
		_connected = false;
		var xhr = new XMLHttpRequest;
		xhr.onreadystatechange = function(){
			if (xhr.readyState==XMLHttpRequest.DONE){
				if (xhr.status==200) handleMessage(xhr.responseText);
				else console.log("Handshake returned status",xhr.status);
			}
		};
		xhr.open('POST',url);
		xhr.setRequestHeader('Content-Type', 'application/json;charset=UTF-8');
		xhr.send(JSON.stringify([{
			channel:'/meta/handshake', version:'1.0',
			supportedConnectionTypes:['websocket','long-polling']
		}]));
	}

	function handleMessage(message){
		if (!message) return console.log("Skipping empty message");
		if ("string"===typeof message) message = JSON.parse(message);
		if (message instanceof Array) return message.forEach(handleMessage);
		console.log("received",JSON.stringify(message));
		// TODO: handle advice field for any message
		if(message.channel=="/meta/handshake"){
			console.assert(message.successful,"TODO: handle unsuccessful handshake");
			if (message.successful){
				_clientId  = message.clientId;
				_connected = true;
				if (~message.supportedConnectionTypes.indexOf('websocket')){
					socket.url = url.replace( /^(?:\w+:\/\/)/, 'ws://' );
				}
				publish('/meta/connect',{connectionType:'websocket'},{beforeOthers:true});
			}
		} else {
			if (!_paths[message.channel]){
				var parts = message.channel.split('/');
				_paths[message.channel] = parts.map(function(_,i){ return parts.slice(0,i+1).join('/') }).reverse();
			}
			_paths[message.channel].forEach(function(path,index){
				if (_calls[path]) _calls[path].forEach(function(o){
					if ( (index==0) || (index==1 && o.wild) || (o.wild=='/**') ){
						o.callback(message.data);
					}
				});
			});
		}
	}

	function _webSocketStatusChange(){
		if (!socket) return;
		console.log("websocket "+_socketStatus[socket.status]);
		switch(socket.status){
			case WebSocket.Open:
				_processQueue();
			break;
			case WebSocket.Error:
				console.log("websocket error:", socket.errorString);
			break;
		}
	}

	function _processQueue(){
		console.log("Processing queue",new Date);
		if (socket.status!=WebSocket.Open){
			// TODO: attempt to reconnect socket if closed or error
			console.log("queue WebSocket status:",_socketStatus[socket.status]);
			return;
		}
		_queue.forEach(function(message){
			message.clientId = _clientId;
			console.log('sending over socket:',JSON.stringify(message));
			socket.sendTextMessage(JSON.stringify(message));
		});
		_queue.length=0;
	}

	function subscribe( channel, callback ){
		var parts = /^(.*?)(\/\*{1,2})?$/.exec(channel);
		var base=parts[1], wild=parts[2];
		if (!_calls[base]) _calls[base]=[];
		var index = _calls[base].length;
		_calls[base].push({callback:callback,wild:wild});
		publish('/meta/subscribe',{subscription:channel});
		return { cancel:function(){ _calls[base].splice(index,1) } };
	}

	function publish( channel, data, options ){
		if (!options) options={};
		var message = { channel:channel };
		Object.keys(data).forEach(function(key){ message[key] = data[key] });
		_queue[options.beforeOthers ? 'unshift' : 'push'](message);
		_processQueue();
	}

	WebSocket {
		id: socket
		Component.onCompleted: {
			socket.textMessageReceived.connect(handleMessage);
			socket.statusChanged.connect(_webSocketStatusChange);
		}
	}

	Timer {
		id: delayedRetryConnect
		interval: 1000*retry
		repeat:   false
		running:  false
		onTriggered: if (!_connected) connect();
	}

	Component.onCompleted:{
		_socketStatus[WebSocket.Connecting] = 'connecting';
		_socketStatus[WebSocket.Open]       = 'open';
		_socketStatus[WebSocket.Error]      = 'error';
		_socketStatus[WebSocket.Closing]    = 'closing';
		_socketStatus[WebSocket.Closed]     = 'closed';
	}
}
