import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

//import 'package:dart_ari_proxy/ari_apps/app_ivr.dart';
import 'package:dart_ari_proxy/ari_apps/call_queue/agents.dart';
import 'package:dart_ari_proxy/ari_apps/call_queue/call_queue.dart';
import 'package:dart_ari_proxy/ari_client/PlaybackApi.dart';
import 'package:dart_ari_proxy/ari_client/cdr.dart';
import 'package:dart_ari_proxy/ari_client/dashboard_client.dart';
import 'package:dart_ari_proxy/ari_client/events/channel_destroyed.dart';
import 'package:dart_ari_proxy/ari_client/events/channel_dtmf_received.dart';
import 'package:dart_ari_proxy/ari_client/events/channel_state_change.dart';
import 'package:dart_ari_proxy/ari_client/events/playback_finished.dart';
import 'package:dart_ari_proxy/ari_client/events/stasis_end.dart';
import 'package:dart_ari_proxy/ari_client/misc.dart';
import 'package:dotenv/dotenv.dart';
import 'package:eventify/eventify.dart';
import 'package:uuid/uuid.dart';

import '../ari_client.dart';
import '../ari_client/BridgesApi.dart';
import '../ari_client/events/stasis_start.dart';
import '../globals.dart';

//Steps to speak to operate a call queue
// 1.

Ari client = Ari();
//var endpoint = "SIP/7000/1057";

String recorderIp = "10.43.0.55";
int recorderPort = 0;

HttpClient httpRtpClient = HttpClient();

 CallQueue callQueue = CallQueue(agent_nums);
//CallQueue callQueue = CallQueue(['SIP/7000/1057', 'SIP/7000/3332']);
CallQueue callQueue = CallQueue(['SIP/7000/1016', 'SIP/7000/1057']);
Map<String, CallRecording> voiceRecords = {};

Map<String, Timer> callTimers = {};

Future<int> rtpPort(String filename) async {
  // baseUrl.path = baseUrl.path + '/channels';

  //10.100.54.137
  var uri = Uri(
      scheme: "http",
      userInfo: "",
      host: "zqa1.zesco.co.zm",
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
      client.incomingChannels[channel.id] = channel;
      var playback = client.playback();
      //state.currentPlayback = playback;

      channel.play(playback, (err, playback) {
        // ignore errors
      }, media: ['sound:queue-callswaiting']);
      originate(channel, false, playback, false);
      //getOrCreateHoldingBridge(channel);
    });

    //actveCalls.set(channel.id, channel.id);
    //callsWaiting.set(channel.id, channel.id);

    //errors.set(channel.id, 0);
    //sendCdr();

    //originate(channel);
  } else {
    if (event.args.length > 0 && event.args[0] == 'dialed') {
      client.dialedChannels[channel.id] = channel;
    }
  }
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

void originate(Channel channel, bool incomingStasisEnd, Playback playback,
    bool localDialedChannelDestroyed) async {
  // var err = holdingBridge.addChannel(channels: [channel.id]);
  // err.then((value) {
  //   var error = holdingBridge.startMoh();
  // });
  late Listener dialedChannelStasisStart;
  late Listener dialedChannelStasisEnd;

  late Listener dialedChannelStateChange;
  late Listener dialedChannelDestroyed;
  late Listener incomingChannelStsisEnd;
  bool localDialedChannelDestroyed;

  bool succeeded = false;

  Bridge mixingBridge = await client.bridge(type: ['mixing']);
  Uuid uid = Uuid();
  String filename = uid.v1();

  int rtpport = await rtpPort(filename);

  Agent? agent = callQueue.nextAgent();

  if (agent == null) {
    channel.continueInDialplan(context: 'IVR-15', priority: 1);
  }
  String endpoint = agent!.endpoint;

  if (agent!.state == AgentState.UNKNOWN) {
    print(
        "Uncreasing unknown agent state to: ${agent.statistics.unknownStateCallsTried}");
    agent.statistics.unknownStateCallsTried++;
  }

  var dialed = await client.channel(endpoint: agent!.endpoint);
  // var externalChannel = await client.channel(
  //     app: 'hello',
  //     endpoint: endpoint,
  //     variables: {'CALLERID(name)': endpoint, 'recording': 'yes'});

  // Channel externalChannel = await client.externalMedia(
  //   (err, externalChannel) {
  //     if (err) throw err;
  //   },
  //   app: 'hello',
  //   variables: {'CALLERID(name)': endpoint, 'recording': 'yes'},
  //   external_host: '$recorderIp:$rtpport',
  //   format: 'alaw',
  // );

  Channel? externalChannel; // = await client.externalMedia(
  //   (err, externalChannel) {
  //     if (err) throw err;
  //   },
  //   app: 'hello',
  //   variables: {'CALLERID(name)': endpoint, 'recording': 'yes'},
  //   external_host: '$recorderIp:$rtpport',
  //   format: 'alaw',
  // );

  // channel.on('ChannelDestroyed', null, (event, dialedChannel) {
  //   // print("Channel Event name: ${event.eventName}");
  //   // print("Event data: ${event.eventData}");
  //   // print("Event sender: ${event.sender}");
  //   // print("");

  //   voiceRecords.remove(channel.id);
  // });

  dialedChannelStasisStart =
      dialed.on('StasisStart', null, (event, dialedChannel) {
    print('Dialed ${dialed.id} entered stasis application');
    // print("Event name: ${event.eventName}");
    // print("Event data: ${event.eventData}");
    // print("Event sender: ${event.sender}");
    // print("");
    // //print(event);
    // //CallsInConversation.set(channel.id, channel.id);
    // //sendCdr();

    joinMixingBridge(channel, dialed, mixingBridge);
    // addChannelsToExistingBridge(externalChannel, mixingBridge);
    // //addChannelsToExistingBridge(externalChannel, mixingBridge);
  });

  dialedChannelStateChange =
      dialed.on('ChannelStateChange', null, (event, dialedChannel) async {
    //  print('Dialed status to: ${event.channel.state}');

    Channel ch = event.sender as Channel;
    if (ch.state == 'Up') {
      // print("Dialed Event name: ${event.eventName}");
      // print("Event data: ${event.eventData}");
      // print("Event sender: ${event.sender}");
      // print('Dialed status to: ${ch.state}');
      // print("");

      succeeded = true;

      voiceRecords[channel.id] = CallRecording(
          file_name: filename,
          file_path: filename,
          agent_number: endpoint,
          phone_number: channel.caller.number);

      print("Initialised the recording: ${voiceRecords[channel.id]}");

      agent.statistics.answereCalls++;
      agent.status = AgentState.ONCONVERSATION;
      playback.stop((callback) {});

      externalChannel = await client.externalMedia(
        (err, externalChannel) {
          if (err) throw err;
        },
        app: 'hello',
        variables: {'CALLERID(name)': endpoint, 'recording': 'yes'},
        external_host: '$recorderIp:$rtpport',
        format: 'alaw',
      );

      addChannelsToExistingBridge(externalChannel!, mixingBridge);
    }

    if (ch.state == 'Ringing') {
      // print("Dialed Event name: ${event.eventName}");
      // print("Event data: ${event.eventData}");
      // print("Event sender: ${event.sender}");
      // print('Dialed status to: ${ch.state}');
      // print("");
      print("Agent status changed to state: ${AgentState.LOGGEDIN}");
      agent.state = AgentState.LOGGEDIN;
      agent.statistics.receivedCalls++;
    }
  });

  //incomingChannelStsisEnd = client.statisChannels[channel.id]!
  incomingChannelStsisEnd =
      channel.on('StasisEnd', null, (event, channelOriginating) {
    // print("Channel Event name: ${event.eventName}");
    // print("Event data: ${event.eventData}");
    // print("Event sender: ${event.sender}");
    // print("");
    //stasisStart(event.eventData as StasisStart, event.sender as Channel);
    print(
        'Channel ${client.statisChannels[channel.id]?.id} has exited our application');
    print(
        'Channel ${client.statisChannels[channel.id]?.name} has exited our application');

    //print('Channel ${externalChannel.name} has exited our application');

    incomingStasisEnd = true;

    safeHangup(dialed);

    if (externalChannel != null) {
      client.externalMediaDelete(externalChannel!.id);
    }

    StasisEnd ed = event.eventData as StasisEnd;
    //Channel ch = event.sender as Channel;

    if (dsbClient != null) {
      if (voiceRecords[channel.id] != null) {
        voiceRecords[channel.id]!.duration_number = ed.timestamp.toString();
        // print("Sending recording details to the dashboar");
        dsbClient!.send_call_records(voiceRecords[channel.id]!);
        voiceRecords.remove(channel.id);
      }
    }

    if (callTimers[channel.id] != null) {
      clearTimeout(callTimers[channel.id]!);
      callTimers.remove(channel.id);
    }

    client.statisChannels.remove(channel.id);
  });

  dialedChannelDestroyed =
      dialed.on('ChannelDestroyed', null, (event, dialedChannel) {
    // print("Dialed Event name: ${event.eventName}");
    // print("Event data: ${event.eventData}");
    // print("Event sender: ${event.sender}");
    // print("");
    //print('Dialed ${dialedChannel.id} destroyed');
    //safeHangup(channel);
    localDialedChannelDestroyed = true;
    if (externalChannel != null) {
      client.externalMediaDelete(externalChannel!.id);
    }

    if (succeeded) {
      ChannelDestroyed ed = event.eventData as ChannelDestroyed;
      //Channel ch = event.sender as Channel;

      if (dsbClient != null) {
        if (voiceRecords[channel.id] != null) {
          voiceRecords[channel.id]!.duration_number = ed.timestamp.toString();
          // print("Sending recording details to the dashboar");
          dsbClient!.send_call_records(voiceRecords[channel.id]!);
          voiceRecords.remove(channel.id);
        }
      }
      if (callTimers[channel.id] != null) {
        clearTimeout(callTimers[channel.id]!);
        callTimers.remove(channel.id);
      }
      channel.continueInDialplan(
          context: 'call-rating', priority: 1, extension: 's');

      agent.status = AgentState.IDLE;
    } else {
      channel.continueInDialplan(context: 'IVR-15', priority: 1);
      // if (callTimers[channel.id] != null) {
      //   clearTimeout(callTimers[channel.id]!);
      //   callTimers.remove(channel.id);
      // }
      dialed.off(dialedChannelStasisStart);
      dialed.off(dialedChannelStateChange);

      //client.statisChannels[channel.id]!.off(incomingChannelStsisEnd);
      dialed.off(dialedChannelDestroyed);

      // dialed.off(dialedChannelDestroyed);
      // dialed.off(incomingChannelStsisEnd);

      // dialed.off(dialedChannelStateChange);
      // dialed.off(dialedChannelStasisStart);
      // if (!incomingStasisEnd) {
      //   callTimers[channel.id] = setTimeout(() {
      //     callTimers[channel.id]!.cancel();
      //     originate(channel, incomingStasisEnd, playback);
      //   }, 5000);
      // }
      // if (!incomingStasisEnd && localDialedChannelDestroyed) {
      //   const oneSec = Duration(seconds: 5);
      //   Timer.periodic(oneSec, (Timer t) {
      //     t.cancel();

      //     originate(channel, incomingStasisEnd, playback,
      //         localDialedChannelDestroyed);
      //   });
      // }
    }
  });

  // dialed.on('StasisEnd', (event, dialChannel) {
  //   print('Channel ${dialChannel.name} has exited our application');
  //   safeHangup(channel);
  // });

  //Agent next_agent = callQueue.nextAgent();

  dialed.originate((err, dialed) async {
    if (err) {
      //debug('originate error:', err);
      throw err;
    }
  },
      // endpoint: next_agent.number,
      endpoint: endpoint,
      app: 'hello',
      appArgs: ['dialed'],
      callerId: channel.caller.number);
}

void joinMixingBridge(Channel channel, Channel dialed, Bridge mixingBridge) {
  dialed.on('Dialed StasisEnd', null, (event, dialedChannel) {
    // print("Event name: ${event.eventName}");
    // print("Event data: ${event.eventData}");
    // print("Event sender: ${event.sender}");
    // print("");
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

void call_center_bridge(List<String> args) async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  //recorderIp = env['HTTP_SERVER_ADDRESS']!;
  //recorderPort = int.parse(env['HTTP_SERVER_PORT']!);

  String voice_records = env['DASHBOARD_RECORDER_ENDPOINT']!;
  String cdr_records = env['DASHBOARD_CDR_ENDPOINT']!;

  dsbClient = DasboardClient(Uri.parse(voice_records), Uri.parse(cdr_records));

  WebSocket ws = await client.connect();

  client.on("StasisStart", null, (event, incoming) {
    // print("Event name: ${event.eventName}");
    // print("Event data: ${event.eventData}");
    // print("Event sender: ${event.sender}");
    // print("Event unknown: ${incoming}");
    stasisStart(event.eventData as StasisStart, event.sender as Channel);
  });

  ws.listen((event) {
    var data = json.decode(event);
    switch (data['type']) {
      case "StasisStart":
        {
          StasisStart stasisStartEvent = StasisStart.fromJson(data,
              channel: client.statisChannels[data['channel']['id']]);
          Channel channel = stasisStartEvent.channel;
          if (client.statisChannels[channel.id] != null) {
            client.statisChannels[channel.id]!
                .emit(data['type'], channel, stasisStartEvent);
          } else {
            client.statisChannels[channel.id] = channel;
            client.statisChannels[channel.id]!
                .emit(data['type'], channel, stasisStartEvent);
          }

          client.emit(data['type'], channel, stasisStartEvent);
        }
      case 'StasisEnd':
        {
          StasisEnd stasisEndEvent = StasisEnd.fromJson(data,
              channel: client.statisChannels[data['channel']['id']]);
          Channel channel = stasisEndEvent.channel;

          if (client.statisChannels[channel.id] != null) {
            //print("Emmitting stasis end event: ${data['type']}");
            print("");
            client.statisChannels[channel.id]!
                .emit('StasisEnd', channel, stasisEndEvent);
          } else {
            client.statisChannels[channel.id] = channel;
            client.statisChannels[channel.id]!
                .emit(data['type'], channel, stasisEndEvent);
          }

          client.emit(data['type'], channel, stasisEndEvent);
        }
      case 'ChannelDestroyed':
        {
          ChannelDestroyed channelDestroyedEvent = ChannelDestroyed.fromJson(
              data,
              channel: client.statisChannels[data['channel']['id']]);
          Channel channel = Channel.fromJson(data['channel']);

          if (client.statisChannels[channel.id] != null) {
            client.statisChannels[channel.id]!
                .emit(data['type'], channel, channelDestroyedEvent);
          } else {
            client.statisChannels[channel.id] = channel;
            client.statisChannels[channel.id]!
                .emit(data['type'], channel, channelDestroyedEvent);
          }

          client.emit(data['type'], channel, channelDestroyedEvent);
        }
      case 'ChannelStateChange':
        {
          ChannelStateChange channelStateChangeEvent =
              ChannelStateChange.fromJson(data,
                  channel: client.statisChannels[data['channel']['id']]);
          Channel channel = Channel.fromJson(data['channel']);

          if (client.statisChannels[channel.id] != null) {
            client.statisChannels[channel.id]!
                .emit(data['type'], channel, channelStateChangeEvent);
          } else {
            client.statisChannels[channel.id] = channel;
            client.statisChannels[channel.id]!
                .emit(data['type'], channel, channelStateChangeEvent);
          }

          client.emit(data['type'], channel, channelStateChangeEvent);
        }

      case 'ChannelDtmfReceived':
        {
          ChannelDtmfReceived channelDtmfReceivedEvent =
              ChannelDtmfReceived.fromJson(data);
          Channel channel = Channel.fromJson(data['channel']);

          if (client.statisChannels[channel.id] != null) {
            client.statisChannels[channel.id]!
                .emit(data['type'], channel, channelDtmfReceivedEvent);
          } else {
            client.statisChannels[channel.id] = channel;
            client.statisChannels[channel.id]!
                .emit(data['type'], channel, channelDtmfReceivedEvent);
          }
          client.emit(data['type'], channel, channelDtmfReceivedEvent);
        }

      case 'PlaybackFinished':
        {
          //   print(data);
          PlaybackFinished playbackFinished = PlaybackFinished.fromJson(data);
          Playback playback = Playback.fromJson(data['playback']);
          //   print(statisPlaybacks[data['playback']['id']]);

          //   if (statisPlaybacks[data['playback']['id']] != null) {
          //     // if (stasisStart.args.length > 0) {
          //     //   throw "This channel should be in statisChannels";
          //     // }

          //     if (statisPlaybacks[data['playback']['id']]!.handlers.isNotEmpty) {
          //       playback.handlers =
          //           statisPlaybacks[data['playback']['id']]!.handlers;
          //       statisPlaybacks[data['playback']['id']] = playback;
          //     }
          //   } else {
          //     statisPlaybacks[data['playback']['id']] = playback;
          //   }
          //   // if (handlers[data['type']] != null) {
          //   //   handlers[data['type']]!(playbackFinished, playback);
          //   // }
          //   if (statisPlaybacks[data['playback']['id']] != null) {
          //     if (playback.handlers[data['type']] != null) {
          //       //print("Event fired from existing channel");
          //       playback.handlers[data['type']]!(playbackFinished, playback);
          //     }
          //   }
          // //handlers[data['type']]!(data);
          client.emit(data['type'], playback, playbackFinished);
        }

      default:
        {
          //print("Unhandled event: ${data['type']}");
        }
    }

    // client.emit(e);

    // Function? func = app[e['type']];
    // func!.call(e);
  }, onDone: () {
    setTimeout(() {
      call_center_bridge(args);
    }, 5000);
  }, onError: () {
    setTimeout(() {
      call_center_bridge(args);
    }, 5000);
  });
  print("Connected to asterisk...");
}
