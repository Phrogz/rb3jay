import QtQml 2.2
import QtQuick 2.7
import QtWebSockets 1.0

Item {
	id:root
	// Number of seconds to wait for a connection before retrying; set to 0 to prevent retries
	property real retry: 10

	// Auto-connects to the server once url is set; disconnects when set to ''
	property string url:   ''
	property bool   debug: false

	property string ømyId
	property string østate
	property var    øqueue: []
	property var    øcalls: ({})
	property var    øpaths: ({})

	onUrlChanged: url ? øconnect() : (østatus='');

	function subscribe( channel, callback ){
		if (debug) console.debug("BayeuxClient subscribing to",channel);
		var parts = /^(.*?)(\/\*{1,2})?$/.exec(channel);
		var base=parts[1], wild=parts[2];
		if (!øcalls[base]) øcalls[base]=[];
		var index = øcalls[base].length;
		øcalls[base].push({callback:callback,wild:wild,channel:channel});
		publish('/meta/subscribe',{subscription:channel});
		return { cancel:function(){
			publish('/meta/unsubscribe',{subscription:channel});
			øcalls[base].splice(index,1);
		}};
	}

	function publish( channel, data, options ){
		if (debug) console.debug("BayeuxClient queuing publish to",channel,JSON.stringify(data));
		if (!options) options={};
		var message = { channel:channel };
		Object.keys(data).forEach(function(key){ message[key]=data[key] });
		øqueue[options.beforeOthers ? 'unshift' : 'push'](message);
		øprocessQueue();
	}

	function øconnect(){
		if (!url || østate) return;
		if (retry) retryConnect.restart();
		østate = 'handshake';
		var xhr = new XMLHttpRequest;
		xhr.onreadystatechange = function(){
			if (xhr.readyState==XMLHttpRequest.DONE){
				if (debug){
					console.debug('BayeuxClient xmlhttp recv status',xhr.status);
					console.debug('BayeuxClient xmlhttp recv:',xhr.responseText);
				}
				if (xhr.status==200) øhandleMessage(xhr.responseText);
				else østate='';
			}
		};
		xhr.open('POST',url);
		xhr.setRequestHeader('Content-Type', 'application/json;charset=UTF-8');
		var data = '[{"channel":"/meta/handshake","version":"1.0","supportedConnectionTypes":["websocket","long-polling"]}]';
		if (debug) console.debug('BayeuxClient xmlhttp send:',data);
		xhr.send(data);
	}

	function øhandleMessage(message){
		if (!message) return;
		if ("string"===typeof message) message=JSON.parse(message);
		if (message instanceof Array) return message.forEach(øhandleMessage);
		if (message.advice){
			if (message.advice.reconnect=='retry' && message.advice.interval) retry=message.advice.interval;
			if (message.advice.timeout) socket.advisedTimeout=message.advice.timeout;
		}
		switch(message.channel){
			case '/meta/handshake':
				console.assert(message.successful,"BayeuxClient xmlhttp handshake failed!");
				if (message.successful){
					ømyId = message.clientId;
					if (~message.supportedConnectionTypes.indexOf('websocket')) socket.connect();
					else console.error("BayeuxClient currently only supports WebSocket communication");
				} else østate='';
			break;
			case '/meta/connect':
				if (message.successful) socket.connect();
				else{
					console.warn("BayeuxClient WebSocket connect failed!",message.error);
					østate = '';
					øconnect();
				}
			break;
			default:
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
				message.clientId = ømyId;
				if (debug) console.debug('BayeuxClient websock send:',JSON.stringify(message));
				socket.sendTextMessage(JSON.stringify(message));
			});
			øqueue.length=0;
		} else if (socket.status!=WebSocket.Connecting) øconnect();
	}

	WebSocket {
		id: socket
		property var statusNames: ({})
		property int advisedTimeout: 30000

		property Timer heartbeat: Timer {
			repeat:true; interval:socket.advisedTimeout*0.47
			onTriggered: (socket.status==WebSocket.Open) && øqueue.push([]) && øprocessQueue();
		}

		function connect(){
			active=false; active=true; // toggle status to force reconnect if URL doesn't change
			var socketURL = root.url.replace( /^(?:\w+:\/\/)/, 'ws://' );
			if (url!=socketURL) url=socketURL;
			heartbeat.start();
			publish('/meta/connect',{connectionType:'websocket'},{beforeOthers:true});
			østate='connected';
		}

		onTextMessageReceived: {
			if (debug) console.log('BayeuxClient websock recv:',message);
			øhandleMessage(message);
		}

		onStatusChanged: {
			if (!socket) return debug && console.debug('BayeuxClient WebSocket has been deleted'); // Happens when the app is shutting down
			if (debug) console.debug('BayeuxClient WebSocket status:',statusNames[socket.status]);
			switch(socket.status){
				case WebSocket.Open:
					øprocessQueue();
				break;
				case WebSocket.Error:
					console.log('BayeuxClient WebSocket error:', socket.errorString);
				case WebSocket.Closed:
					if (debug) console.debug('BayeuxClient attempting to reconnect...');
					østate = '';
					øconnect();
					Object.keys(øcalls).forEach(function(base){
						øcalls[base].forEach(function(o){ publish('/meta/subscribe',{subscription:o.channel}) });
					});
				break;
			}
		}

		Component.onCompleted: {
			statusNames[WebSocket.Connecting] = 'WebSocket.Connecting';
			statusNames[WebSocket.Open]       = 'WebSocket.Open';
			statusNames[WebSocket.Closing]    = 'WebSocket.Closing';
			statusNames[WebSocket.Closed]     = 'WebSocket.Closed';
			statusNames[WebSocket.Error]      = 'WebSocket.Error';
		}
	}

	Timer {
		id:retryConnect; interval:1000*retry
		Component.onCompleted:triggered.connect(øconnect);
	}
}
