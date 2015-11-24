var test = require('tape');
var dir  = __dirname.split('/')[__dirname.split('/').length-1];
var file = dir + __filename.replace(__dirname, '') + " > ";

var server = require('../server.js');

test(file + 'test the response on / is "Hello Sohil!"', function(t){
  var options = {
    method: "GET",
    url: "/"
  };
  server.inject(options, function(response) {
    console.log(response.result);
    t.equal(response.result, 'Hello Sohil!', 'Success message goes here!');
    setTimeout(function(){ server.stop(t.end) }, 1);
  });
});
