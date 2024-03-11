import 'dart:convert';
import 'dart:io';

import 'package:dart_ari_proxy/ari_client/BridgesApi.dart';
import 'package:dart_ari_proxy/ari_client/ChannelsApi.dart';
//import 'package:dart_ari_proxy/ari_client/events/event.dart';
import 'package:dart_ari_proxy/ari_client/events/stasis_start.dart';

//import 'ari_client/ChannelsApi.dart';
import 'ari_client/events/channel_destroyed.dart';
import 'ari_client/events/stasis_end.dart';

export 'ari_client/ChannelsApi.dart';
export 'ari_client/events/event.dart';

class Ari {
  Map<String, Function(dynamic event, Channel channel)> handlers = {};

  Map<String, Channel> statisChannels = {};

  void on(String event, Function(dynamic event, Channel channel) callback) {
    handlers[event] = callback;
  }

  void emit(data) {
    //print(data);

    switch (data['type']) {
      case "StasisStart":
        Channel channel;

        // if (data['channel']['name'].contains('UnicastRTP')) {
        //   // print('Channel ${channel.name} has entered our application');
        //   // print(channel.handlers);
        //   // dialed = true;
        //   if (statisChannels[data['channel']['id']] == null) {
        //     throw "Channel should be in stasis channels";
        //   } else {
        //     print("Channel already in stsais Channels");
        //     if (statisChannels[data['channel']['id']]!.handlers.isEmpty) {
        //       throw "channel event handlers should not be empty";
        //     }
        //   }
        // }
        StasisStart stasisStart = StasisStart.fromJson(data);
        if (statisChannels[data['channel']['id']] == null) {
          // if (stasisStart.args.length > 0) {
          //   throw "This channel should be in statisChannels";
          // }
          channel = Channel.fromJson(data['channel']);

          statisChannels[channel.id] = channel;
        } else {
          channel = statisChannels[data['channel']['id']]!;
        }
        if (handlers[data['type']] != null) {
          handlers[data['type']]!(stasisStart, channel);
        }
        //print("Channel event handlers: ${channel.handlers}");
        // if (channel.handlers.isEmpty) {
        //   throw "Channel event handlers cannot be empty";
        // }

        if (channel.handlers[data['type']] != null) {
          //print("Event ${data['type']} fired from channel in stasis");
          channel.handlers[data['type']]!(stasisStart, channel);
        }

      case 'StasisEnd':
        Channel channel;
        StasisEnd stasisEnd = StasisEnd.fromJson(data);
        if (statisChannels[data['channel']['id']] == null) {
          throw "Channel should be in statisChannels map";
        } else {
          channel = statisChannels[data['channel']['id']]!;
        }
        if (handlers[data['type']] != null) {
          handlers[data['type']]!(stasisEnd, channel);
        }
        if (channel.handlers[data['type']] != null) {
          //print("Event ${data['type']} fired from channel in stasis");
          channel.handlers[data['type']]!(stasisEnd, channel);
        }

        statisChannels.remove(channel.id);

      case 'ChannelDestroyed':
        ChannelDestroyed channelDestroyed = ChannelDestroyed.fromJson(data);
        if (handlers[data['type']] != null) {
          //print(data['type']);
          Channel channel = Channel.fromJson(data['channel']);
          if (statisChannels[channel.id] == null) {
            statisChannels[channel.id] = channel;
          }

          handlers[data['type']]!(channelDestroyed, channel);
        }
        if (statisChannels[data['channel']['id']] != null) {
          Channel channel = statisChannels[data['channel']['id']]!;
          if (channel.handlers[data['type']] != null) {
            //print("Event fired from existing channel");
            channel.handlers[data['type']]!(channelDestroyed, channel);
          }
        }

      //handlers[data['type']]!(data);
    }
  }

  Future<WebSocket> connect() async {
    // Random r = new Random();
    final int key = 758485960049485;
// Random r = new Random();
//   String key = base64.encode(List<int>.generate(8, (_) => r.nextInt(256)));

//   HttpClient client = HttpClient(/* optional security context here */);
//   HttpClientRequest request = await client.get('echo.websocket.org', 80,
//       '/foo/ws?api_key=myapikey'); // form the correct url here
//   request.headers.add('Connection', 'upgrade');
//   request.headers.add('Upgrade', 'websocket');
//   request.headers.add('sec-websocket-version', '13'); // insert the correct version here
//   request.headers.add('sec-websocket-key', key);

//   HttpClientResponse response = await request.close();
//   // todo check the status code, key etc
//   Socket socket = await response.detachSocket();

//   WebSocket ws = WebSocket.fromUpgradedSocket(
//     socket,
//     serverSide: false,
//   );

// HttpClient clientLearn = HttpClient(/* optional security context here */);
// HttpClientRequest requestLearn = await clientLearn.get('echo.websocket.org', 80,
//        '/foo/ws?api_key=myapikey'); // form the correct url here

    var uri = Uri(
        scheme: "http",
        userInfo: "",
        host: "10.44.0.55",
        port: 8088,
        path: "ari/events",
        //Iterable<String>? pathSegments,
        query: "",
        queryParameters: {
          'api_key': 'asterisk:asterisk',
          'app': 'hello',
          'subscribe_all': 'true'
        }
        //String? fragment
        );
    HttpClient client = HttpClient();
    HttpClientRequest request = await client.getUrl(uri);
    request.headers.add('connection', 'Upgrade');
    //print('Hello');
    request.headers.add('upgrade', 'websocket');
    request.headers.add('Sec-WebSocket-Version', '13');
//request.headers.add('WebSocket-Version', '13');
    request.headers.add('Sec-WebSocket-Key', key);
    //HttpClientResponse response = await request.close();
    HttpClientResponse response = await request.close();
    //print(response);

    // Socket socket = await response.detachSocket();

    Socket socket = await response.detachSocket();

    WebSocket ws = WebSocket.fromUpgradedSocket(socket, serverSide: false);

    // ws.listen((event) {
    //   var e = json.decode(event);
    //   //print(e['type']);

    //   Function? func = app[e['type']];
    //   func!.call(e);
    // });
    //ws.listen(onData(//), onMessage, onDone: connectonClosed);
    // void on("StasisStart") {
    //   print("Hello");
    // }
    // ws.listen((event) {
    //   var e = json.decode(event);
    //   on(app[e['type']]);
    // },onError: on);
    return ws;
  }

  Bridges bridges = Bridges(); //: Bridges;

  Future<Channel> channel(
      {String? endpoint,
      String? extension,
      String? context,
      String? priority,
      String? label,
      String? app,
      List<String>? appArgs,
      String? callerId,
      String? timeout,
      String? channelId,
      String? otherChannelId,
      String? originator,
      dynamic variables}) async {
    // print("application: $app");
    // print("endpoint: $app");
    var resp = await ChannelsApi.create(
        endpoint: endpoint,
        extension: extension,
        context: context,
        priority: priority,
        label: label,
        app: app,
        appArgs: appArgs,
        callerId: callerId,
        timeout: timeout,
        channelId: channelId,
        otherChannelId: otherChannelId,
        originator: originator,
        variables: variables);
    var channelJson;
    //resp.then((value) {
    //print(resp.resp);
    channelJson = json.decode(resp.resp);
    Channel channel = Channel.fromJson(channelJson);

    statisChannels[channel.id] = channel;

    return channel;
    //});
    //return null;
  }

  Future<Channel> externalMedia(
    Function(bool, Channel) callback, {
    required String app, //: string;
    dynamic variables, //?: Containers;
    required external_host, //: string;
    String? encapsulation, //?: string;
    String? transport, //?: string;
    String? connection_type, //?: string;
    required String format, //: string;
    String? direction, //?: string;
  }) async {
    var resp = await ChannelsApi.externalMedia(
        app: app,
        variables: variables,
        external_host: external_host,
        encapsulation: encapsulation,
        transport: transport,
        connection_type: connection_type,
        format: format,
        direction: direction);

    //print(resp.resp);

    var channelJson = resp.resp;

    Channel channel = Channel.fromJson(jsonDecode(channelJson));

    statisChannels[channel.id] = channel;
    return channel;

    // resp.then((value) {
    //   if (value.statusCode == 200 || value.statusCode == 204)
    //     callback(false, this);
    //   else
    //     callback(true, this);
    // });
  }

  Future<Bridge> bridge(
      {String? name, String? bridgeId, List<String>? type}) async {
    var resp = await BridgesAPI.createOrUpdate(
        name: name, bridgeId: bridgeId, type: type);
    //print(resp.resp);
    var bridgeJson = jsonDecode(resp.resp);
    var bridge = Bridge.fromJson(bridgeJson);
    return bridge;
  }
}
