import 'dart:io';
//import 'dart:convert';
import 'package:dart_ari_proxy/ari_client/events/channel_destroyed.dart';
import 'package:dart_ari_proxy/ari_client/events/channel_state_change.dart';
import 'package:dart_ari_proxy/ari_client/events/stasis_end.dart';
import 'package:dart_ari_proxy/ari_client/events/stasis_start.dart';
import 'package:dart_ari_proxy/globals.dart';
//import 'package:eventify/eventify.dart';
import 'package:events_emitter/events_emitter.dart';

import 'models.dart';

import 'ApplicationsApi.dart';
import 'BridgesApi.dart';
import 'DeviceStateApi.dart';
import 'EndpointsApi.dart';
import 'PlaybackApi.dart';
import 'RecordingsApi.dart';
import 'SoundsApi.dart';
import 'ChannelsApi.dart';

class ARI extends EventEmitter {
  /**
   * Creates a new awry API instance, providing clients for all available
   * Asterisk ARI endpoints.
   *
   * @param {object} params
   * @param {string} params.username The username to send with the request.
   * @param {string} params.password The password to send with the request.
   * @param {string} params.baseUrl The base url, without trailing slash,
   *  of the root Asterisk ARI endpoint. i.e. 'http://myserver.local:8088/ari'.
   */

  ARI() {}
  /** @type {ApplicationsAPI} */
  static ApplicationsApi applications = ApplicationsApi();

  /** @type {AsteriskAPI} */
  //this.asterisk = new AsteriskAPI(params);

  /** @type {BridgesAPI} */
  late BridgesAPI bridges = BridgesAPI();

  /** @type {DeviceStatesAPI} */
  late DeviceStateApi deviceStates = DeviceStateApi();

  /** @type {EndpointsAPI} */
  late EndpointsAPI endpoints = EndpointsAPI();

  /** @type {EventsAPI} */
  //this.events = new EventsAPI(params);

  /** @type {MailboxesAPI} */
  //this.mailboxes = new MailboxesAPI(params);

  /** @type {PlaybacksAPI} */
  late PlaybackApi playbacks = PlaybackApi();

  /** @type {RecordingsAPI} */
  late RecordingsApi recordings = RecordingsApi();

  /** @type {SoundsAPI} */
  late SoundsApi sounds = new SoundsApi();

  /** @type {ChannelsAPI} */
  late ChannelsApi channels = ChannelsApi();

  //Params params = Params('asterisk', 'asterisk', '10.44.0.55');

  // String username;
  // String password;
  // String baseUrl;
  // HttpClient client = HttpClient();

  void stasisStart(StasisStart message) => emit('StasisStart', message);

  void stasisEnd(StasisEnd message) => emit('StasisEnd', message);

  void channelDestroyed(ChannelDestroyed message) =>
      emit('channelDestroyed', message);

  void channelStateChange(ChannelStateChange message) =>
      emit('ChannelStateChange', message);

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
          'api_key': api_key,
          'app': 'hello',
          'subscribe_all': 'true'
        }
        //String? fragment
        );

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
}
