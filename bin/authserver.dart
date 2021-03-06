library authServer;

import "dart:io";
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import "package:args/args.dart";
import "package:http/http.dart" as http;
import "package:redstone/server.dart" as app;
import 'package:shelf/shelf.dart' as shelf;
import 'package:uuid/uuid.dart';
import "package:authServer/session.dart";

part '../API_KEYS.dart';
part '../lib/auth.dart';
part '../lib/data.dart';


Map<String,Session> SESSIONS = {};
Uuid uuid = new Uuid();
ArgResults argResults;
bool loadCert = true;

void main(List<String> arguments)
{
  //setup command line argument parsing
  final parser = new ArgParser()
  //use --no-load-cert to ignore certification loading
    ..addFlag("load-cert", defaultsTo: true, help: "Enables certificate loading for certificate")
    ..addOption("port", defaultsTo:"8383", help: "Port to run the server on");

  argResults = parser.parse(arguments);
  loadCert = argResults['load-cert'];

	int port;
	try	{port = int.parse(argResults['port']);}
	catch(error){port = 8383;}

	//try to parse ENV var
	if (Platform.environment['AUTH_PORT'] != null &&
	    Platform.environment['AUTH_PORT'].isNotEmpty)
	{
	  try {port = int.parse(Platform.environment['AUTH_PORT']);}
	  catch (error){port = 8383;}
	}

	if (loadCert)
	{
	  try
	  {
	    SecureSocket.initialize(database: "sql:./certdb", password: certdbPassword);
	    app.setupConsoleLog();
	    app.start(port:port, autoCompress:true, secureOptions: {#certificateName: "childrenofurCert"});
	  } catch (error) {print("Unable to start server with signed certificate.");}
	}
	else
	{
	  //start up server in non-cert-certified developer mode
	  app.setupConsoleLog();
	  app.start(port:port);
	}

}

//add a CORS header to every request
@app.Interceptor(r'/.*')
crossOriginInterceptor()
{
	if (app.request.method == "OPTIONS")
	{
		//overwrite the current response and interrupt the chain.
		app.response = new shelf.Response.ok(null, headers: _createCorsHeader());
		app.chain.interrupt();
	}
	else
	{
  	//process the chain and wrap the response
		app.chain.next(() => app.response.change(headers: _createCorsHeader()));
	}
}

@app.Route('/serverStatus')
Map getServerStatus()
{
  Map statusMap = {};
  try
  {
    statusMap['status'] = "OK";
    statusMap['loadCert'] = loadCert;
  }
  catch(e){logMessage("Error getting server status: $e");}
  return statusMap;
}

void logMessage(String message)
{
  print("(${new DateTime.now().toString()}) $message");
}
_createCorsHeader() => {"Access-Control-Allow-Origin": "*","Access-Control-Allow-Headers": "Origin, X-Requested-With, Content-Type, Accept"};
