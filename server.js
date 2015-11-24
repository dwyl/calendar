var assert = require('assert');
var Hapi   = require('hapi'); // require the hapi module
var server = new Hapi.Server();

server.connection({
	host: 'localhost',
	port: Number(process.env.PORT) // defined by environment variable or .env file
});

server.route({
  method: 'GET',
  path: '/',
  handler: function(request, reply) {
    reply('Hello Sohil!');
  }
});

server.start(function(err){ // boots your server
  assert(!err, "FAILED TO Start Server", err);
	console.log('Now Visit: http://localhost:'+server.info.port);
});

module.exports = server;
