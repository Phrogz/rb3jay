import QtQml 2.2
import QtQuick 2.7
import QtWebSockets 1.0

Item {
	id: root

	property bool autoConnect: true
	property bool retry: true
	property string url: ''
	property string _clientId: ''
	property var _queue: []
	property var _calls: ({})
	property var _paths: ({})

	function connect(){
		var xhr = new XMLHttpRequest;
		xhr.onreadystatechange = function(){
			switch (xhr.readyState){
				case XMLHttpRequest.DONE:
					handleMessage(xhr.responseText);
				break;
				// case XMLHttpRequest.HEADERS_RECEIVED:
				// 	console.log('headers',xhr.getAllResponseHeaders());
				// break;
				default:
					console.log('TODO: handle XHR readyState:',xhr.readyState);
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
				_clientId = message.clientId;
				if (~message.supportedConnectionTypes.indexOf('websocket')){
					socket.url = url.replace( /^(?:\w+:\/\/)/, 'ws://' );
					// socket.active = active;
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
		switch(socket.status){
			case WebSocket.Connecting:
				console.log("websocket connecting")
				// TODO:
			break;
			case WebSocket.Open:
				console.log("websocket open")
				_processQueue();
			break;
			case WebSocket.Error:
				console.log("websocket error:", socket.errorString);
				// TODO:
			break;
			case WebSocket.Closing:
				console.log("websocket closing")
				// TODO:
			break;
			case WebSocket.Closed:
				console.log("websocket closed")
				// TODO:
			break;
			default:
				console.log('ws status unrecognized:',socket.status);
		}
	}

	function _processQueue(){
		console.log("Processing queue",new Date);
		if (socket.status!=WebSocket.Open){
			// TODO: attempt to reconnect socket in x seconds; let .Open status change trigger this
			console.log("WebSocket not ready, trying again in "+delayedProcessQueue.interval+"ms");
			delayedProcessQueue.start();
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

	Component.onCompleted: {
		if (autoConnect && url) connect();
	}

	WebSocket {
		id: socket
		Component.onCompleted: {
			socket.textMessageReceived.connect(handleMessage);
			socket.statusChanged.connect(_webSocketStatusChange);
		}
	}

	Timer {
		id: delayedProcessQueue
		interval: 100
		repeat: false
		running: false
		Component.onCompleted: triggered.connect(_processQueue);
	}
}
