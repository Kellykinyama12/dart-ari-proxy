import 'dart:io';

import 'package:dart_ari_proxy/ari_apps/call_queue/agents.dart';
import 'package:dart_ari_proxy/globals.dart';

// Function requestHander;

class HttpAPIServer {
  HttpAPIServer(String ip, int port) {
    HttpServer.bind(InternetAddress(ip), port).then((HttpServer server) {
      server.listen((HttpRequest request) {
        print("Request from ${request.uri.host}");
        // request.response.write("Hello world!");
        // request.response.close();

        var queryParams = request.uri.queryParameters;
        //print("query parameters: $queryParams");
        if (queryParams['login'] != null) {
          if (callQueue.agents[queryParams['endpoint']] != null) {
            callQueue.agents[queryParams['endpoint']]!.state =
                AgentState.LOGGEDIN;
            callQueue.agents[queryParams['endpoint']]!.status = AgentState.IDLE;
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
        } else {
          request.response
            ..statusCode = HttpStatus.badRequest
            ..close();
        }
      });
    });
  }
}
