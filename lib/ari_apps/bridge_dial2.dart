import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:uuid/uuid.dart';

import '../ari_client.dart';
import '../ari_client/BridgesApi.dart';
import '../ari_client/cdr.dart';
import '../ari_client/events/stasis_start.dart';

import 'package:dart_ari_proxy/globals.dart';

Ari client = Ari();
var endpoint = "SIP/7000/2035";

Map<String, Cdr> cdrRecords = {};
Map<String, CallRecording> voiceRecords = {};

String recorderIp = "";
int recorderPort = 0;

HttpClient httpRtpClient = HttpClient();

Future<int> rtpPort(String filename) async {
  // baseUrl.path = baseUrl.path + '/channels';

  //10.100.54.137
  var uri = Uri(
      scheme: "http",
      userInfo: "",
      host: "10.100.54.137",
      port: 8080,
      //path: "ari/channels/$channelId/answer",
      //Iterable<String>? pathSegments,
      query: "",
      queryParameters: {'filename': filename}
      //String? fragment
      );

//HttpClientRequest request = await client.getUrl(uri);
  //var uri = Uri.http(baseUrl, '/channels/${channelId}/answer', qParams);
  HttpClientRequest request = await httpRtpClient.postUrl(uri);
  HttpClientResponse response = await request.close();
  //print(response);
  final String stringData = await response.transform(utf8.decoder).join();
  print(response.statusCode);
  var port = jsonDecode(stringData); //print(stringData);

  return port['rtp_port'];
}

stasisStart(StasisStart event, Channel channel) {
  bool dialed = event.args.length > 0 ? event.args[0] == 'dialed' : false;

  if (channel.name.contains('UnicastRTP')) {
    print('Channel ${channel.name} has entered our application');
    dialed = true;
  }

  if (!dialed) {
    //throw variable;
    var resp = channel.answer();
    resp.then((err) {
      print('Channel ${channel.name} has entered our application');

      cdrRecords[channel.id] = Cdr(
          channel: channel.id,
          clid: channel.caller.name,
          src: channel.caller.number,
          dst: 'c-17',
          dcontext: 'custom-context',
          calldate: event.timestamp.toString());

      originate(channel);
      //getOrCreateHoldingBridge(channel);
    });

    //actveCalls.set(channel.id, channel.id);
    //callsWaiting.set(channel.id, channel.id);

    //errors.set(channel.id, 0);
    //sendCdr();
  }
  // else{
  //   if(event.args.length > 0 && event.args[0] == 'dialed'){

  //   }

  // }
}

// void getOrCreateHoldingBridge(Channel channel) {
//   // client.bridges.list((err: Error, bridges: Bridge[]) {
//   //     let mixingBridges = bridges.filter((candidate: Bridge) => {
//   //         return candidate['bridge_type'] === 'mixing';
//   //     });
//   //     print('Mixing bridges', mixingBridges.length);

//   //     client.channels.list((err: Error, channels: Channel[]) => {
//   //         let activeChannels = channels;
//   //         print('Active channels', activeChannels.length);
//   //         print('Active bridges', bridges.length);
//   //     });
//   // });

//   var bridges = client.bridges.list();
//   bridges.then((bridgesList) {
//     //print("Bridges: ${bridgesList.length}");
//     var holdingBridge = bridgesList.where((Bridge candidate) {
//       return candidate.bridge_type == 'holding';
//     }).toList();
//     //print(holdingBridge.length);

//     if (holdingBridge.isNotEmpty) {
//       print('Using existing holding bridge ${holdingBridge[0].id}');

//       originate(channel, holdingBridge[0]);
//     } else {
//       var bridge = client.bridges.create(type: "holding"); // {

//       bridge.then((bridge) {
//         print('Created new holding bridge ${bridge.id}');

//         originate(channel, bridge);
//       });
//     }
//   });
// }
void addChannelsToExistingBridge(Channel externalChannel, Bridge mixingBridge) {
  var error = mixingBridge.addChannel(channels: [externalChannel.id]);

  error.then((err) {
    if (err) {
      throw err;
    }
  });
}

void originate(Channel channel) async {
  // var err = holdingBridge.addChannel(channels: [channel.id]);
  // err.then((value) {
  //   var error = holdingBridge.startMoh();
  // });

  Bridge mixingBridge = await client.bridge(type: ['mixing']);
  Uuid uid = Uuid();

  String filename = uid.v1();

  int rtpport = await rtpPort(filename);

  var dialed = await client.channel(endpoint: endpoint);
  // var externalChannel = await client.channel(
  //     app: 'hello',
  //     endpoint: endpoint,
  //     variables: {'CALLERID(name)': endpoint, 'recording': 'yes'});

  Channel externalChannel = await client.externalMedia(
    (err, externalChannel) {
      if (err) throw err;
    },
    app: 'hello',
    variables: {'CALLERID(name)': endpoint, 'recording': 'yes'},
    external_host: '$recorderIp:$rtpport',
    format: 'alaw',
  );

  dialed.on('ChannelDestroyed', (event, dialed) {
    print('Dialed ${dialed.id} destroyed');
    safeHangup(channel);
  });

  dialed.on('StasisStart', (event, dialedChannel) {
    print('Dialed ${dialed.id} entered stasis application');
    //print(event);
    //CallsInConversation.set(channel.id, channel.id);
    //sendCdr();

    joinMixingBridge(channel, dialed, mixingBridge);
    addChannelsToExistingBridge(externalChannel, mixingBridge);
    //addChannelsToExistingBridge(externalChannel, mixingBridge);
  });

  // dialed.on('StasisEnd', (event, dialChannel) {
  //   print('Channel ${dialChannel.name} has exited our application');
  //   safeHangup(channel);
  // });

  channel.on('StasisEnd', (event, channel) {
    print('Channel ${channel.name} has exited our application');
    safeHangup(dialed);

    if (cdrRecords[channel.id] != null) {
      cdrRecords[channel.id]!.hangupdate = event.timestamp.toString();

      if (dsbClient != null) {
        dsbClient!.send_cdr(cdrRecords[channel.id]!);
      }
    }

    if (voiceRecords[channel.id] != null && dsbClient != null) {
      voiceRecords[channel.id]!.duration_number = event.timestamp.toString();
      dsbClient!.send_call_records(voiceRecords[channel.id]!);
    }
    voiceRecords.remove(channel.id);
    cdrRecords.remove(channel.id);
  });

  dialed.on('ChannelStateChange', (event, dialed) {
    print('Dialed status to: ${event.channel.state}');

    if (event.channel.state == 'Up') {
      //CallsInConversation.set(channel.id, channel.id);
      print('Dialed status to: ${event.channel.state}');

      voiceRecords[channel.id] = CallRecording(
          file_name: filename,
          file_path: filename,
          agent_number: endpoint,
          phone_number: cdrRecords[channel.id]!.src!);
    }
  });

  dialed.originate((err, dialed) async {
    if (err) {
      //debug('originate error:', err);
      throw err;
    }
  },
      endpoint: endpoint,
      app: 'hello',
      appArgs: ['dialed'],
      callerId: channel.caller.number);
}

void joinMixingBridge(Channel channel, Channel dialed, Bridge mixingBridge) {
  dialed.on('StasisEnd', (event, dialed) {
    //sendCdr(cdr);
    dialedExit(channel, mixingBridge);
  });

  var resp = dialed.answer();
  resp.then((value) {
    moveToMixingBridge(channel, dialed, mixingBridge);
  });
}

void moveToMixingBridge(Channel channel, Channel dialed, Bridge mixingBridge) {
  print(
      'Adding channel ${channel.name} and dialed channel ${dialed.name} to bridge ${mixingBridge.id}');
  // holdingBridge.removeChannel(channel: [channel.id]).then((value) {
  //   mixingBridge.addChannel(channels: [channel.id, dialed.id]);
  // });

  mixingBridge.addChannel(channels: [channel.id, dialed.id]);
}

dialedExit(Channel dialed, Bridge mixingBridge) {
  print(
      'Dialed channel ${dialed.name} has left our application, destroying mixing bridge ${mixingBridge.id}');

  mixingBridge.destroy((err) {
    if (err) {
      throw err;
    }

    dialed.hangup((err) => {});
  });
}

void safeHangup(Channel channel) {
  print('Hanging up channel ${channel.name}');

  channel.hangup((err) {
    // ignore error
  });
}

void bridge_dial2(List<String> args) async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  recorderIp = env['HTTP_SERVER_ADDRESS']!;
  recorderPort = int.parse(env['HTTP_SERVER_PORT']!);
  endpoint = env['PHONE_ENDPOINT']!;
  WebSocket ws = await client.connect();

  client.on("StasisStart", (event, incoming) {
    //print(event);
    stasisStart(event, incoming);
  });

  ws.listen((event) {
    var e = json.decode(event);
    //print(e['type']);
    client.emit(e);

    // Function? func = app[e['type']];
    // func!.call(e);
  });
}
