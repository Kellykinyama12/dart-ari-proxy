import 'dart:convert';
import 'dart:io';

import 'package:dart_ari_proxy/ari_client.dart';
import 'package:dart_ari_proxy/ari_client/BridgesApi.dart';
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

String regex =
    r'[^\p{Alphabetic}\p{Mark}\p{Decimal_Number}\p{Connector_Punctuation}\p{Join_Control}\s]+';

stasisStart(StasisStart event, Channel channel) {
  bool dialed = event.args.length > 0 ? event.args[0] == 'dialed' : false;
  if (channel.name.contains('UnicastRTP')) {
    print('Channel ${channel.name} has entered our application');
    print(channel.handlers);
    dialed = true;
  }
  if (!dialed) {
    //throw variable;
    channel.answer((err) {
      if (err) {
        throw err;
      }

      print('Channel ${channel.name} has entered our application');

      getOrCreateHoldingBridge(channel);
    });

    actveCalls[channel.id] = channel.id;
    callsWaiting[channel.id] = channel.id;
    CallsInConversation[channel.id] = channel.id;

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

void getOrCreateHoldingBridge(Channel channel) {
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

  client.bridges.list((err, bridges) {
    var holdingBridge = bridges.firstWhere((Bridge candidate) {
      return candidate.bridge_type == 'holding';
    });

    if (holdingBridge != null) {
      print('Using existing holding bridge ${holdingBridge.id}');

      originate(channel, holdingBridge);
    } else {
      client.bridges.create((err, holdingBridge) {
        if (err) {
          throw err;
        }

        print('Created new holding bridge ${holdingBridge.id}');

        originate(channel, holdingBridge);
      }, type: "holding");
    }
  });
}

void originate(Channel channel, Bridge holdingBridge) async {
  bool callSucceed = false;

  holdingBridge.addChannel((err) {
    if (err) {
      throw err;
    }

    holdingBridge.startMoh((err) {
      // ignore error
    });
  }, channels: [channel.id]);
  var endpoint = "SIP/7000/2035";

  var dialed = await client.channel(endpoint: endpoint);
  //var bridge = await client.bridge();
  // var externalChannel = await client.channel(
  //     app: 'hello',
  //     endpoint: endpoint,
  //     variables: {'CALLERID(name)': endpoint, 'recording': 'yes'});

  // String rtpIp = "10.100.54.52";
  // int port = 5464;

  rtp_server(
      rtpIp,
      port + rtpPortCounter,
      dialed.caller.number +
          DateTime.now()
              .toString()
              .replaceAll(RegExp(regex, unicode: true), ''));

  Channel externalChannel = await client.externalMedia(
    (err, externalChannel) {
      if (err) throw err;
    },
    app: 'hello',
    variables: {'CALLERID(name)': endpoint, 'recording': 'yes'},
    external_host: '$rtpIp:${port + rtpPortCounter}',
    format: 'alaw',
  );
  rtpPortCounter++;
  if (rtpPortCounter - port > 2000) rtpPortCounter = 0;
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
  });

  // externalChannel.on('StasisStart', (event, streamed) {
  //   throw externalChannel.name;
  //   print('Adding recording channel ${externalChannel.name} to the bridge');
  //   addChannelsToExistingBridge(externalChannel, mixingBridge);
  // });

  //print(externalChannel.handlers);

  dialed.on('ChannelDestroyed', (event, dialed) {
    print("Saftely hingup up in originate on ChannelDestroyed");
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

    joinMixingBridge(channel, dialed, holdingBridge, mixingBridge);
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
  mixingBridge.addChannel((err) {
    if (err) {
      throw err;
    }
  }, channels: [externalChannel.id]);
}

void joinMixingBridge(Channel channel, Channel dialed, Bridge holdingBridge,
    Bridge mixingBridge) async {
  dialed.on('StasisEnd', (event, dialed) {
    //sendCdr(cdr);
    dialedExit(dialed, mixingBridge);
  });

  dialed.answer((err) {
    if (err) {
      throw err;
    }
  });

  mixingBridge.create((err, mixingBridge) {
    if (err) {
      throw err;
    }

    print('Created mixing bridge ${mixingBridge.id}');

    moveToMixingBridge(channel, dialed, mixingBridge, holdingBridge);
  });
}

void moveToMixingBridge(Channel channel, Channel dialed, Bridge mixingBridge,
    Bridge holdingBridge) {
  print(
      'Adding channel ${channel.name} and dialed channel ${dialed.name} to bridge ${mixingBridge.id}');

  holdingBridge.removeChannel((err) {
    if (err) {
      throw err;
    }

    mixingBridge.addChannel((err) {
      if (err) {
        throw err;
      }
    }, channels: [channel.id, dialed.id]);
  }, channel: [channel.id]);
}

dialedExit(Channel dialed, Bridge mixingBridge) {
  print(
      'Dialed channel ${dialed.name} has left our application, destroying mixing bridge ${mixingBridge.id}');

  mixingBridge.destroy((err) {
    if (err) {
      throw err;
    }
  });
}

void safeHangup(Channel channel) {
  print('Hanging up channel ${channel.name}');

  channel.hangup((err) {
    // ignore error
  });
}

void main(List<String> arguments) async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  rtpIp = env['RTP_ADDRESS']!;
  port = int.parse(env['RTP_PORT']!);
  print("Listening on: $rtpIp:$port");

  String wsIp = env['WS_SERVER_ADDRESS']!;
  int wsPort = int.parse(env['WS_SERVER_PORT']!);
  String redisIp = env['REDIS_ADDRESS']!;
  int redisPort = int.parse(env['REDIS_PORT']!);
  String redisPassword = env['REDIS_PASSWORD']!;
  wsServer = WsServer(wsIp, wsPort, redisIp, redisPort, redisPassword);

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
