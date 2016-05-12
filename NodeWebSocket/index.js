var http = require('http');
var url = require('url');
var _ = require('lodash');
var WebSocketServer = require('ws').Server;

var version = "v4";

var _lookup = {};

function saveLastInform(ws){
  ws.lastinform =  (new Date()).toISOString();
}

function log(message){
  console.log(new Date() + ' -- ' + message);
}


// WebSocket SERVER

var wssrv = new WebSocketServer({ port: 3051 });

wssrv.on('connection', function connection(ws) {

  ws.mediaspot_id = ws.upgradeReq.headers.name;

  if(ws.mediaspot_id === undefined)
    return;

  saveLastInform(ws);
  log("CONNECTION FROM  " + ws.mediaspot_id + " ");  

  ws.id = ws.mediaspot_id; // assign the received ID to the incoming connection (ws client only ever sends its own ID)
  _lookup[ws.id] = ws; // include in _lookup table  
  log(ws.mediaspot_id + " added");

  //console.log(ws);

  ws.on('message', function incoming(message) {
    saveLastInform(ws);
    log("MESSAGE RECEIVED FROM " + ws.mediaspot_id + " :");
    log(message);
    // ws.id = message; // assign the received ID to the incoming connection (ws client only ever sends its own ID)
    // _lookup[ws.id] = ws; // include in _lookup table
  });

  ws.on('close', function close() {
    log("CLOSE EVENT FROM " + ws.mediaspot_id);
    delete _lookup[ws.mediaspot_id];
    log(ws.mediaspot_id + " removed");
  });

  ws.on('pong', function() {
    saveLastInform(ws);
    log("PONG FROM " + ws.mediaspot_id);
  });

  ws.on('ping', function() {
    saveLastInform(ws);
    log("PING FROM " + ws.mediaspot_id);

    if(!_lookup[ws.mediaspot_id]){
      _lookup[ws.mediaspot_id] = ws;
      log(ws.mediaspot_id + " added back");
    }
  });
});



// HTTP SERVER

var srv = http.createServer(function (srvreq, srvres) {

  if(srvreq.url == '/version'){
    srvres.writeHead(200, {'Content-Type': 'application/json'});
    srvres.end(version);
    return;
  }

  if(srvreq.url == '/ping'){

    wssrv.clients.forEach(function each(client) {
      client.ping();
    });

    log('ping sent to all clients');
    srvres.writeHead(200, {'Content-Type': 'application/json'});    
    srvres.end('ping sent to all clients');
    return;
  }

  if(srvreq.url == '/mediaspots'){

    var res = _.map(_lookup, function(ws, key){
      return {
        mediaspot_id: key,
        lastinform: ws.lastinform
      };
    });

    srvres.writeHead(200, {'Content-Type': 'application/json'});
    srvres.end(JSON.stringify(res,null,2));
    return;
  }

  var rxurl = url.parse(srvreq.url, true);
  var mediaspot_id = rxurl.query.mediaspot_id;


  var message = rxurl.query.message;

  if(_lookup[mediaspot_id]){

    try{

      _lookup[mediaspot_id].send(message, function(err){ // send informrequest to the user over websocket
        if(err){
          var msg = 'error while sending "'+ message + '" to ' + mediaspot_id;
          log(msg + ' :');
          console.log(err);
          srvres.writeHead(500, {'Content-Type': 'text/plain'});
          srvres.end(msg);
        }
        else{
          log('"'+ message + '" sent to ' + mediaspot_id);
          srvres.writeHead(200, {'Content-Type': 'text/plain'});
          srvres.end('"'+ message + '" sent to ' + mediaspot_id);
        }
      });

    }
    catch(e){
      var msg = 'error while sending "'+ message + '" to ' + mediaspot_id;
      log(msg + ' :');
      console.log(e);
      srvres.writeHead(500, {'Content-Type': 'text/plain'});
      srvres.end(msg);
    }

  }
  else{
    srvres.writeHead(404, {'Content-Type': 'text/plain'});
    log(mediaspot_id + ' not found')
    srvres.end(mediaspot_id + ' not found. "' + message + '" was not sent');
  }

}).listen(3052); // or whatever – listening for incoming trigger from Ruby

//forever --uid "syncserver-node-ws" -al /home/ubuntu/tapngo-web-sync/current/NodeWebSocket/production.log start NodeWebSocket/index.js

