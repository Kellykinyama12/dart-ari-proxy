import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:redis/redis.dart';

import 'ari_client.dart';

import 'dart:convert' show utf8;

class wsSipServer {
  wsSipServer(String ip, int port)
      : this.ip = ip,
        this.port = port {
    conn = RedisConnection();
    conn!.connect('10.44.0.55', 6379).then((Command command) {
      print("connected to redis");
      command.send_object(["AUTH", "zsco@123deraboof"]).then((var response) {
        print(response);
      });
      cmd = command;
    });
  }

  void intialize() async {
    Ari ariClient = Ari();
    WebSocket ariSocket = await ariClient.connect();

    Command command = await RedisConnection().connect('10.44.0.55', 6379);
    command.send_object(["AUTH", "zsco@123deraboof"]).then((var response) {
      //print(response);
    });
    //final pubsub = PubSub(command);
    //pubsub.sub(["monkey"]);

    ariSocket.listen((event) {
      //print(event);
      command.send_object(["PUBLISH", "monkey", event]).then((var response) {
        //print(event);
      });
      //print(event);
    });
    HttpClient client = HttpClient();
    //client.setCredentials(scope, creds);

    // client.addCredentials(
    //    uri,scheme, HttpClientBasicCredentials("asterisk", "aseterisk"));

    // client.authenticate = (uri, scheme, realm) {
//   client.addCredentials(
//       uri,scheme, HttpClientBasicCredentials("asterisk", "aseterisk"));
//       return true;
// };

    HttpServer.bind(InternetAddress(ip), port).then((server) {
      print('Listening on ws://${server.address.address}:${server.port}');
      server.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          WebSocketTransformer.upgrade(request).then(handleWebSocket);
          print("Status code: ${request.response.statusCode}");
        } else {
          //print("Request received: ${request.uri.path}");
          void sendResponse(HttpClientRequest requestProxied) {
//void addCredentials(Uri url, String realm, HttpClientCredentials credentials);
//               client.authenticate = (uri, scheme, realm) {
//   client.addCredentials(
//       uri,scheme, HttpClientBasicCredentials("asterisk", "aseterisk"));

// };
            requestProxied.close().then((response) {
              response.transform(utf8.decoder).join().then((stringData) {
                request.response.statusCode = response.statusCode;
                request.response.write(stringData);
                //request.response.statusCode=response.statusCode;

                request.response.close();

                print("Data form server: $stringData");
                print("Status code: ${response.statusCode}");
              });
            });
          }

          var Url = //

              Uri(
                  scheme: "http",
                  userInfo: "",
                  host: "10.44.0.55",
                  port: 8088,
                  path: request.uri.toString(),
                  //Iterable<String>? pathSegments,
                  query: "",
                  queryParameters: {'api_key': 'asterisk:asterisk'}
                  //String? fragment
                  );

          if (request.uri.path.indexOf("/ari/api-docs") != -1) {
            client.getUrl(Url).then((requestProxied) {
              requestProxied.close().then((response) {
                response.transform(utf8.decoder).join().then((stringData) {
                  var decode = jsonDecode(stringData);
                  //print("Response: ${decode["basePath"]}");
                  var uriToChange = Uri.parse(decode["basePath"]);
                  //print("Uri: $uriToChange");
                  // print("Host: ${uriToChange.host}");
                  var changedTo =
                      "http://${server.address.address}:${server.port}${uriToChange.path}";
                  decode["basePath"] = changedTo;
                  //print("Changing to: ${decode["basePath"]}");
                  request.response.statusCode = response.statusCode;
                  request.response.write(jsonEncode(decode));
                  //request.response.statusCode=response.statusCode;
                  request.response.close();
                });
              });
            });
          } else {
            print("Request: ${request.requestedUri}");
            print("Method: ${request.method}");
            print("User info: ${request.uri.userInfo}");
            print("Scheme: ${request.uri.scheme}");
            print("Path: ${request.uri.path}");
            print("Query: ${request.uri.query}");
            print("Query parameters: ${request.uri.queryParametersAll}");
            print("Data: ${request.uri.data}");

            // final credentionals = <String, String>{
            //   'api_key': 'asterisk:astersk'
            // };
// final gasGiants = <int, String>{5: 'Jupiter', 6: 'Saturn'};
// final iceGiants = <int, String>{7: 'Uranus', 8: 'Neptune'};
// planets.addEntries(gasGiants.entries);
// planets.addEntries(iceGiants.entries);
            //request.uri.queryParameters.addEntries(credentionals.entries);

            if (request.contentLength == -1) {
              //_sendResponse(request, ''); // Handle empty content
            } else {
              utf8.decodeStream(request).then((data) {
                //} => _sendResponse(request, data));

                var Url = //

                    Uri(
                        scheme: "http",
                        userInfo: request.uri.userInfo,
                        host: "10.44.0.55",
                        port: 8088,
                        path: request.uri.path,
                        //Iterable<String>? pathSegments,
                        query: request.uri.query,
                        queryParameters: {'api_key': 'asterisk:astersk'}
                        //String? fragment
                        );

                switch (request.method.toLowerCase()) {
                  case "post":
                    {
                      //if (request.method.toLowerCase() == "post") {
                      Url = //

                          Uri(
                              scheme: "http",
                              userInfo: request.uri.userInfo,
                              host: "10.44.0.55",
                              port: 8088,
                              path: request.uri.path,
                              //Iterable<String>? pathSegments,
                              query: request.uri.query,
                              queryParameters: {'api_key': 'asterisk:astersk'}
                              //String? fragment
                              );
                      client.postUrl(Url).then(
                          (requestProxied) => sendResponse(requestProxied));
                      //}
                    }
                  case "get":
                    {
                      //else if (request.method.toLowerCase() == "get") {
                      Url = //

                          Uri(
                              scheme: "http",
                              userInfo: request.uri.userInfo,
                              host: "10.44.0.55",
                              port: 8088,
                              path: request.uri.path,
                              //Iterable<String>? pathSegments,
                              query: request.uri.query,
                              queryParameters: {'api_key': 'asterisk:astersk'}
                              //String? fragment
                              );
                      client.getUrl(Url).then(
                          (requestProxied) => sendResponse(requestProxied));
                      // requestProxied.headers.set("Authorization", 'api_key:asterisk:asterisk');
                      //}
                    }
                  case "put":
                    {
                      // else if (request.method.toLowerCase() == "put") {
                      Url = //

                          Uri(
                              scheme: "http",
                              userInfo: request.uri.userInfo,
                              host: "10.44.0.55",
                              port: 8088,
                              path: request.uri.path,
                              //Iterable<String>? pathSegments,
                              query: request.uri.query,
                              queryParameters: {'api_key': 'asterisk:astersk'}
                              //String? fragment
                              );
                      client.putUrl(Url).then(
                          (requestProxied) => sendResponse(requestProxied));
                      //}
                    }

                  case "delete":
                    {
                      //else if (request.method.toLowerCase() == "delete") {
                      Url = //

                          Uri(
                              scheme: "http",
                              userInfo: request.uri.userInfo,
                              host: "10.44.0.55",
                              port: 8088,
                              path: request.uri.path,
                              //Iterable<String>? pathSegments,
                              query: request.uri.query,
                              queryParameters: {'api_key': 'asterisk:astersk'}
                              //String? fragment
                              );
                      client.deleteUrl(Url).then(
                          (requestProxied) => sendResponse(requestProxied));
                      //}
                    }
                  //print(request.uri.scheme);
                } //print(request.uri.scheme);
              });
            }
          }
        }
      });
    });
  }

  void handleWebSocket(WebSocket socket) async {
    // RawDatagramSocket udpClient =
    //     await RawDatagramSocket.bind(InternetAddress(udpServerIp), 0);
    //   .then((RawDatagramSocket socket) {
    //print('UDP client ready to receive');
    //print('${udpClient.address.address}:${udpClient.port}');

    //handler = ReqHandler(socket.address.address, socket.port, socket);

    onNewMessageFromWS(String data) {
      print(data);
      // udpClient.send(data.toString().codeUnits, InternetAddress(udpServerIp),
      //     udpServerPort);
    }

    final connection = RedisConnection();
    Command command = await connection.connect('10.44.0.55', 6379);

    command.send_object(["AUTH", "zsco@123deraboof"]);

    PubSub pubsub = PubSub(command);
    pubsub.subscribe(["monkey"]);

    socket.listen(
      (data) {
        print('Received: $data');
        onNewMessageFromWS(data);
        //socket.add('Echo: ${json.encode(resp)}');
      },
      onDone: () {
        print('Connection closed');
      },
      onError: (error) {
        print('Error: $error');
      },
    );

    final stream = pubsub.getStream();
    var streamWithoutErrors = stream.handleError((e) => print("error $e"));

    await for (final msg in streamWithoutErrors) {
      var kind = msg[0];
      var food = msg[2];
      if (kind == "message") {
        //print("monkey got ${food}");
        socket.add(food);
      } else {
        print("received non-message ${msg}");
      }
    }
  }

  // This function starts a basic HTTP proxy server that listens on port 8081 locally for incoming connections.
// When a connection is received, it makes a request to 127.0.0.1:8080 and proxies the request and response between the client and destination server.
// It handles HTTPS requests by making secure connections.
// Request headers like Host are modified to match the destination.
// Redirects (3xx responses) from the destination server are also handled.
// void startProxyServer() async {
//   // Create a server socket that listens on port 8081
//   final serverSocket = await ServerSocket.bind('127.0.0.1', 8082);
//   print('Proxy server listening on port 8081');

//   // Start accepting incoming connections
//   await for (var socket in serverSocket) {
//     // Handle each incoming connection in a separate isolate
//     await handleConnection(socket);
//   }
// }

// // This function handles an incoming connection by making a request to the destination server and proxying the request and response between the client and destination server.
// Future<void> handleConnection(Socket clientSocket) async {
//   // Connect to the destination server (127.0.0.1:8080)
//   final destinationSocket = await Socket.connect('10.44.0.55', 8088);
//   print('Connected to destination server');

//   // Proxy the request from the client to the destination server
//   await proxyRequest(clientSocket, destinationSocket);

//   // Proxy the response from the destination server back to the client
//   await proxyResponse(destinationSocket, clientSocket);

//   // Close the sockets
//   clientSocket.close();
//   destinationSocket.close();
// }

// // This function proxies the request from the client to the destination server.
// Future<void> proxyRequest(Socket clientSocket, Socket destinationSocket) async {
//   // Read the request from the client
//   final request = await clientSocket.transform(utf8.decoder).join();

//   // Modify the request headers to match the destination server
//   final modifiedRequest = modifyRequestHeaders(request);

//   // Write the modified request to the destination server
//   destinationSocket.write(modifiedRequest);
// }

// // This function modifies the request headers to match the destination server.
// String modifyRequestHeaders(String request) {
//   // Modify the Host header to match the destination server
//   final modifiedRequest = request.replaceAll('Host: 127.0.0.1:8081', 'Host: 127.0.0.1:8080');

//   return modifiedRequest;
// }

// // This function proxies the response from the destination server back to the client.
// Future<void> proxyResponse(Socket destinationSocket, Socket clientSocket) async {
//   // Read the response from the destination server
//   final response = await destinationSocket.transform(utf8.decoder).join();

//   // Write the response to the client
//   clientSocket.write(response);
// }

  String ip;
  int port;
  RedisConnection? conn; // = RedisConnection();
  Command? cmd;
}
