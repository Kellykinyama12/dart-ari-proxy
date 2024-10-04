import 'dart:io';

import 'package:dart_ari_proxy/ari_apps/call_queue/agents.dart';
import 'package:dart_ari_proxy/globals.dart';
import 'package:redis/redis.dart';

// Function requestHander;

class HttpAPIServer {
  String redisIp;
  int redisPort;
  String redisPassword;

  HttpAPIServer(
      String ip, int port, this.redisIp, this.redisPort, this.redisPassword) {
    HttpServer.bind(InternetAddress(ip), port).then((HttpServer server) {
      print('Listening on ws://${server.address.address}:${server.port}');
      server.listen((HttpRequest request) async {
        print("Request from ${request.uri.host}");
        // request.response.write("Hello world!");
        // request.response.close();
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          WebSocketTransformer.upgrade(request).then(handleWebSocket);
          print("Status code: ${request.response.statusCode}");
        } else {
          var queryParams = request.uri.queryParameters;
          //print("query parameters: $queryParams");
          if (queryParams['login'] != null) {
            if (callQueue.agents[queryParams['endpoint']] != null) {
              callQueue.agents[queryParams['endpoint']]!.state =
                  AgentState.LOGGEDIN;
              callQueue.agents[queryParams['endpoint']]!.status =
                  AgentState.IDLE;
              print(
                  "agent ${callQueue.agents[queryParams['endpoint']]!.endpoint} logged in");
            }
            request.response
              ..statusCode = HttpStatus.ok
              ..close();
          } else if (queryParams['logout'] != null) {
            if (callQueue.agents[queryParams['endpoint']] != null) {
              callQueue.agents[queryParams['endpoint']]!.state =
                  AgentState.LOGGEDOUT;
              print(
                  "agent ${callQueue.agents[queryParams['endpoint']]!.endpoint} logged out");
            }
            request.response
              ..statusCode = HttpStatus.ok
              ..close();
            //callQueue.agents.remove(queryParams['endpoint']);
          } else if (queryParams['status'] != null) {
            if (callQueue.agents[queryParams['endpoint']] != null &&
                queryParams['status'] == 'WITHDRAWN') {
              callQueue.agents[queryParams['endpoint']]!.state =
                  AgentState.ONWITHDRAW;
              print(
                  "agent ${callQueue.agents[queryParams['endpoint']]!.endpoint} om withdraw");
            }
            request.response
              ..statusCode = HttpStatus.ok
              ..close();
          } else if (queryParams['agentstatus'] != null) {
            if (callQueue.agents[queryParams['endpoint']] != null &&
                queryParams['status'] == 'WITHDRAWN') {
              if (currentAgent != null) {
                currentAgent!(queryParams['endpoint']!);
              }
              print(
                  "agent ${callQueue.agents[queryParams['endpoint']]!.endpoint} om withdraw");
            }
            request.response
              ..statusCode = HttpStatus.ok
              ..close();
          } else {
            request.response
              ..statusCode = HttpStatus.badRequest
              ..close();
          }
        }
      });
    });
  }

  void handleWebSocket(WebSocket socket) async {
    onNewMessageFromWS(String data) {
      //print(data);
      // udpClient.send(data.toString().codeUnits, InternetAddress(udpServerIp),
      //     udpServerPort);
    }

    sendMessageToWS(String data) {
      socket.add(data);
    }

    final connection = RedisConnection();
    Command command = await connection.connect(redisIp, redisPort);

    command.send_object(["AUTH", redisPassword]);

    PubSub pubsub = PubSub(command);
    pubsub.subscribe(["monkey"]);

    socket.listen(
      (data) {
        //print('Received: $data');
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

    streamWithoutErrors.listen((msg) {
      var kind = msg[0];
      var food = msg[2];
      if (kind == "message") {
        //print("monkey got ${food}");
        socket.add(food);
      } else {
        print("received non-message ${msg}");
      }
    });
  }
}
