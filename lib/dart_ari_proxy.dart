import 'dart:convert';
import 'dart:io';

import 'package:redis/redis.dart';

import 'ari_client.dart';

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
      command.send_object(["PUBLISH", "monkey", event]).then((var response) {
        //print(response);
      });
      //print(event);
    });
    HttpClient client = HttpClient();

    // client.authenticate = (uri, scheme, realm) {
//   client.addCredentials(
//       uri, "10.44.0.55", HttpClientBasicCredentials('api_key', api_key));

// };

    HttpServer.bind(ip, port).then((server) async {
      print('Listening on ws://${server.address.address}:${server.port}');
      // HttpClient client = HttpClient();
      await for (HttpRequest request in server) {
        //request.response.headers.set("Sec-WebSocket-Protocol", "sip");
        // print(stringData);
        // request.response.write('Hello world');
        // request.response.close();
        //print(response);
        print("Request received: ${request.uri.toString()}");

        if (WebSocketTransformer.isUpgradeRequest(request)) {
          WebSocketTransformer.upgrade(request).then(handleWebSocket);
          print("Status code: ${request.response.statusCode}");
          //   ..statusCode)
        } else {
          // request.response
          //   ..statusCode = HttpStatus.forbidden
          //   ..close();

          //HttpClient client = HttpClient();

          // var Url = //

          //     Uri(
          //         scheme: "http",
          //         userInfo: "",
          //         host: "10.44.0.55",
          //         port: 8088,
          //         path: request.uri.toString(),
          //         //Iterable<String>? pathSegments,
          //         query: "",
          //         queryParameters: {'api_key': api_key}
          //         //String? fragment
          //         );

          // print("Request received: ${Url.data}");

          // HttpClientRequest requestProxied = await client.getUrl(Url);

          // HttpClientResponse response = await requestProxied.close();
          // final stringData = await response.transform(utf8.decoder).join();
          // request.response.statusCode = response.statusCode;
          // request.response.write(stringData);
          // //request.response.statusCode=response.statusCode;
          // request.response.close();
          // print("Response: $stringData");
        }
      }
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

  String ip;
  int port;
  RedisConnection? conn; // = RedisConnection();
  Command? cmd;
}
