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
		console.log("Handling message",typeof message,JSON.stringify(message));
		if (!message) return console.log("Skipping empty message");
		if ("string"===typeof message) message = JSON.parse(message);
		console.log("Handling message",typeof message,JSON.stringify(message));		
		if (message instanceof Array) return message.forEach(handleMessage);
		// TODO: handle advice field for any message		
		switch(message.channel){
			case "/meta/handshake":
				console.assert(message.successful,"TODO: handle unsuccessful handshake");
				if (message.advice) console.assert(message.advice,"TODO: handle unsuccessful handshake");
				if (message.successful){
					_clientId = message.clientId;
					if (~message.supportedConnectionTypes.indexOf('websocket')){
						socket.url = url.replace( /^(?:\w+:\/\/)/, 'ws://' );
						// socket.active = active;
					}
					publish('/meta/connect',{connectionType:'websocket'});
				}
			break;
			default:
				console.log("TODO: handle receipt of message",message);
		}
	}

	function _webSocketStatusChange(){
		switch(socket.status){
			case WebSocket.Connecting:
				console.log("websocket connecting")
				// TODO: 
			break;
			case WebSocket.Open:
				console.log("websocket open")
				// TODO: 
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
			console.log("WebSocket not ready, trying again in "+delayedProcessQueue.interval+"ms");
			delayedProcessQueue.start();
			return;
		}
		_queue.forEach(function(message){
			socket.sendTextMessage(JSON.stringify(message));
		});
	}

	function subscribe( channel, callback ){

	}

	function publish( channel, data, options ){
		if (!options) options={};
		var message = { channel:channel, clientId:_clientId };
		Object.keys(data).forEach(function(key){ message[key] = data[key] });
		_queue.push(message);
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
