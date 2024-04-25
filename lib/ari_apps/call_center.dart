import 'dart:convert';
import 'dart:io';

import 'package:dart_ari_proxy/ari_client.dart';
import 'package:dart_ari_proxy/ari_client/BridgesApi.dart';
import 'package:dart_ari_proxy/ari_client/cdr.dart';
import 'package:dart_ari_proxy/ari_client/dashboard_client.dart';
import 'package:dart_ari_proxy/ari_client/events/stasis_start.dart';
import 'package:dart_ari_proxy/ari_http_proxy.dart';
import 'package:dart_ari_proxy/globals.dart';
import 'package:dart_ari_proxy/recorder/rtp_server.dart';
import 'package:dart_ari_proxy/ari_client/statistics.dart';

import 'package:dotenv/dotenv.dart';

//import 'package:dart_ari_proxy/ari_client/Events/event.dart';
//import 'package:dart_ari_proxy/ari_http_proxy.dart';
//import 'package:dart_ari_proxy/dart_ari_proxy.dart';
//lib\ari_http_proxy.dart
Ari client = Ari();

String rtpIp = "10.100.54.52";
int port = 5464;
int rtpPortCounter = 0;
var endpoint = "SIP/7000/2035";

String regex =
    r'[^\p{Alphabetic}\p{Mark}\p{Decimal_Number}\p{Connector_Punctuation}\p{Join_Control}\s]+';

Map<String, Cdr> cdrRecords = {};
Map<String, CallRecording> voiceRecords = {};

stasisStart(StasisStart event, Channel channel) {
  bool dialed = event.args.length > 0 ? event.args[0] == 'dialed' : false;
  if (channel.name.contains('UnicastRTP')) {
    print('Channel ${channel.name} has entered our application');
    print(channel.handlers);
    dialed = true;

    rtpPortCounter++;
    if (rtpPortCounter - port > 2000) rtpPortCounter = 0;
  }
  if (!dialed) {
    //throw variable;
    channel.answer((err) {
      if (err) {
        throw err;
      }

      print('Channel ${channel.name} has entered our application');

      //originate(channel);
      getOrCreateHoldingBridge(channel);
    });

    actveCalls[channel.id] = channel.id;
    callsWaiting[channel.id] = channel.id;
    CallsInConversation[channel.id] = channel.id;

    cdrRecords[channel.id] = Cdr(
        channel: channel.id,
        clid: channel.caller.name,
        src: channel.caller.number,
        dst: 'c-17',
        dcontext: 'custom-context',
        calldate: event.timestamp.toString());

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

void getOrCreateHoldingBridge(Channel channel) async {
  // client.bridges.list((err: Error, bridges: Bridge[]) {
  //     let mixingBridges = bridges.filter((candidate: Bridge) => {
  //         return candidate['bridge_type'] === 'mixing';
  //     });
  //     print('Mixing bridges', mixingBridges.length);

  //     client.channels.list((err: Error, channels: Channel[]) => {
  //         let activeChannels = channels;
  //         print('Active channels', activeChannels.length);
  //         print('Active bridges', bridges.length);
  //     });
  // });

  var bridges = client.bridges.list();
  bridges.then((bridgesList) {
    print("Bridges: ${bridgesList.length}");
    var holdingBridge = bridgesList.where((Bridge candidate) {
      return candidate.bridge_type == 'holding';
    }).toList();
    print(holdingBridge.length);

    if (holdingBridge.isNotEmpty) {
      print('Using existing holding bridge ${holdingBridge[0].id}');

      originate(channel, holdingBridge[0]);
    } else {
      var bridge = client.bridges.create(type: "holding"); // {

      bridge.then((bridge) {
        print('Created new holding bridge ${bridge.id}');

        originate(channel, bridge);
      });
    }
  });

  // client.bridges.list((err, bridges) {
  //   var holdingBridge = bridges.firstWhere((Bridge candidate) {
  //     return candidate.bridge_type == 'holding';
  //   });

  //   if (holdingBridge != null) {
  //     print('Using existing holding bridge ${holdingBridge.id}');

  //     originate(channel, holdingBridge);
  //   } else {
  //     client.bridges.create((err, holdingBridge) {
  //       if (err) {
  //         throw err;
  //       }

  //       print('Created new holding bridge ${holdingBridge.id}');

  //       originate(channel, holdingBridge);
  //     }, type: "holding");
  //   }
  // });
}

void originate(Channel channel, Bridge holdingBridge) async {
  bool callSucceed = false;

  var err = holdingBridge.addChannel(channels: [channel.id]);
  err.then((value) {
    var error = holdingBridge.startMoh();
  });
  //var endpoint = "SIP/7000/2035";

  var dialed = await client.channel(endpoint: endpoint);
  //var bridge = await client.bridge();
  // var externalChannel = await client.channel(
  //     app: 'hello',
  //     endpoint: endpoint,
  //     variables: {'CALLERID(name)': endpoint, 'recording': 'yes'});

  // String rtpIp = "10.100.54.52";
  // int port = 5464;
  final filename = dialed.caller.number +
      DateTime.now()
          .toString()
          .replaceAll(RegExp(regex, unicode: true), '')
          .replaceAll(" ", '');

  rtp_server(rtpIp, port + rtpPortCounter, filename);

  Channel externalChannel = await client.externalMedia(
    (err, externalChannel) {
      if (err) throw err;
    },
    app: 'hello',
    variables: {'CALLERID(name)': endpoint, 'recording': 'yes'},
    external_host: '$rtpIp:${port + rtpPortCounter}',
    format: 'alaw',
  );

  //print("Externa channel: ${externalChannel}");
  Bridge mixingBridge = await client.bridge(type: ['mixing']);

  channel.on('StasisEnd', (event, channel) {
    print("Saftely hungup up in originate on stasisEnd");
    //errors.set(channel.id, errors.get(channel.id)! + 1);
    //if (errors.get(channel.id)! > 1) throw 'event is already handled';
    //actveCalls.delete(channel.id);
    //callsWaiting.delete(channel.id);
    //CallsInConversation.delete(channel.id);
    //cdr.hangupdate = event.timestamp;
    //cdr.lastapp = event.application;
    //print('Posting to CDR');
    channel.removeAllListeners('StasisEnd');
    //postCdr(cdr);
    //sendCdr();

    actveCalls.remove(channel.id);

    callsWaiting.remove(channel.id);

    CallsInConversation.remove(channel.id);
    safeHangup(dialed);
    safeHangup(externalChannel);

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

  // externalChannel.on('StasisStart', (event, streamed) {
  //   throw externalChannel.name;
  //   print('Adding recording channel ${externalChannel.name} to the bridge');
  //   addChannelsToExistingBridge(externalChannel, mixingBridge);
  // });

  //print(externalChannel.handlers);

  dialed.on('ChannelDestroyed', (event, dialed) {
    print("Saftely hangup up in originate on ChannelDestroyed");
    //sendCdr(event);
    //CallsInConversation.delete(channel.id);
    //cdr.hangupdate = event.timestamp;
    //if (!callSucceed) cdr.disposition = 'Busy';
    //print("Call succeded: ${callSucceed}");

    if (callSucceed) {
      channel.continueInDialplan((err) {
        if (err) safeHangup(channel);
      }, context: 'call-rating', priority: 1, extension: 's');
    } else {
      channel.continueInDialplan((err) {
        if (err) safeHangup(channel);
      }, context: 'IVR-15', priority: 1);

      safeHangup(channel);
    }
    //postCdr(cdr);
    //sendCdr(cdr);
    //print(cdr);
    safeHangup(externalChannel);
    safeHangup(channel);
  });
  //var agent = {} as Agent;
  dialed.on('ChannelStateChange', (event, dialed) {
    print('Dialed status to: ${event.channel.state}');
    //print(event);

    //cdr.dstchannel = dialed.id;
    //cdr.dst = event.channel.caller;
    //cdr.dst = event.channel.connected;
    //event.channel.connected
    //print(dialed.caller);
    //cdr.answerdate = event.timestamp;
    // CallsInConversation.set(channel.id, channel.id);
    //callsWaiting.delete(channel.id);
    if (event.channel.state == 'Up') {
      //CallsInConversation.set(channel.id, channel.id);
      print('Dialed status to: ${event.channel.state}');
      // cdr.disposition = 'Answered';

      callsWaiting.remove(channel.id);
      CallsInConversation[channel.id] = channel.id;

      //CallsInConversation.remove(channel.id);
      callSucceed = true;
      //if (agent != null) agent.loggedIn = true;

      if (cdrRecords[channel.id] != null) {
        cdrRecords[channel.id]!.answerdate = event.timestamp.toString();
        cdrRecords[channel.id]!.dstchannel = dialed.id;
      }

      voiceRecords[channel.id] = CallRecording(
          file_name: filename,
          file_path: filename,
          agent_number: endpoint,
          phone_number: cdrRecords[channel.id]!.src!);
    }
    //var e =JSON.parse(event);
    //sendCdr();
    //safeHangup(channel);
  });

  dialed.on('StasisStart', (event, dialed) {
    print('Dialed ${dialed.id} entered stasis application');
    //print(event);
    //CallsInConversation.set(channel.id, channel.id);
    //sendCdr();

    joinMixingBridge(channel, dialed, mixingBridge, holdingBridge);
    // addChannelsToExistingBridge(externalChannel, mixingBridge);
    addChannelsToExistingBridge(externalChannel, mixingBridge);
  });

  // dialed.on('StasisEnd', (event, dialed) {
  //   print('Dialed ${dialed.id} entered stasis application');
  //   //print(event);
  //   //CallsInConversation.set(channel.id, channel.id);
  //   //sendCdr();

  //   //joinMixingBridge(channel, dialed, holdingBridge);
  //   safeHangup(channel);
  // });

  if (client.statisChannels[dialed.id] == null) {
    throw "Dialed should be in statisChannels array";
  }
  //else
  //print(dialed.handlers);

  // agents.forEach((value, key) => {d
  //     print(value);
  // });

  // var agentFilter = Array.from(agents.values()).filter(
  //     (value: Agent) => value.state == AgentState.UNKNOWN || value.state == AgentState.IDLE,
  // );

  // agentFilter.forEach(value => {
  //     if (agent == null || agent.agentSetNumber == undefined) agent = value;
  //     else if (value.callsServed >= agent.callsServed) {
  //         agent = value;
  //     }
  // });

  //     agent.agentSetNumber == undefined || agent.agentSetNumber == null
  //         ? 'SIP/7000/3636'
  //         : 'SIP/7000/' + agent.agentSetNumber;
  // print('Calling agent:', endpoint);

  //client.statisChannels[dialed.id] = dialed;

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

void joinExistingMixingBridge(Channel channel, Bridge mixingBridge) {}

void addChannelsToExistingBridge(Channel externalChannel, Bridge mixingBridge) {
  var error = mixingBridge.addChannel(channels: [externalChannel.id]);

  error.then((err) {
    if (err) {
      throw err;
    }
  });
}

void joinMixingBridge(Channel channel, Channel dialed, Bridge holdingBridge,
    Bridge mixingBridge) async {
  dialed.on('StasisEnd', (event, dialed) {
    //sendCdr(cdr);
    dialedExit(channel, mixingBridge);
  });

  dialed.answer((err) {
    if (err) {
      throw err;
    }
  });

  //var bridge = mixingBridge.create();

  //bridge.then((value) {
  //print('Created mixing bridge ${value.id}');

  moveToMixingBridge(channel, dialed, mixingBridge, holdingBridge);
  //});
}

void moveToMixingBridge(Channel channel, Channel dialed, Bridge mixingBridge,
    Bridge holdingBridge) {
  print(
      'Adding channel ${channel.name} and dialed channel ${dialed.name} to bridge ${mixingBridge.id}');

  var error1 = holdingBridge.removeChannel(channel: [channel.id]);
  error1.then((value) {
    var error = mixingBridge.addChannel(channels: [channel.id, dialed.id]);

    error.then((err) {
      if (err) {
        throw err;
      }
    });
  });
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

void call_center(List<String> arguments) async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  rtpIp = env['RTP_ADDRESS']!;
  port = int.parse(env['RTP_PORT']!);
  print("Listening on: $rtpIp:$port");

  String wsIp = env['WS_SERVER_ADDRESS']!;
  int wsPort = int.parse(env['WS_SERVER_PORT']!);
  String redisIp = env['REDIS_ADDRESS']!;
  int redisPort = int.parse(env['REDIS_PORT']!);
  String redisPassword = env['REDIS_PASSWORD']!;

  endpoint = env['PHONE_ENDPOINT']!;
  print("Endpoint: $endpoint");
  wsServer = WsServer(wsIp, wsPort, redisIp, redisPort, redisPassword);

  String voice_records = env['DASHBOARD_RECORDER_ENDPOINT']!;
  String cdr_records = env['DASHBOARD_CDR_ENDPOINT']!;

  dsbClient = DasboardClient(Uri.parse(voice_records), Uri.parse(cdr_records));

  //wsServer!.intialize();
  // wsSipServer proxy=wsSipServer("127.0.0.1",8082);
  // proxy.intialize();

  client.on("StasisStart", (event, incoming) {
    //print(event);
    stasisStart(event, incoming);
  });

  WebSocket ws = await client.connect();

  ws.listen((event) {
    var e = json.decode(event);
    //print(e['type']);
    client.emit(e);

    // Function? func = app[e['type']];
    // func!.call(e);
  });
}
