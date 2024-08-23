import 'dart:convert';
import 'dart:io';
import 'dart:math';

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
import 'package:dotenv/dotenv.dart';
import 'package:uuid/uuid.dart';

import '../ari_client.dart';
import '../ari_client/BridgesApi.dart';
import '../ari_client/events/stasis_start.dart';
import '../globals.dart';

Ari client = Ari();
var endpoint = "SIP/7000/3636";

String recorderIp = "10.43.0.55";
int recorderPort = 0;

HttpClient httpRtpClient = HttpClient();

CallQueue callQueue = CallQueue(agent_nums);

Map<String, CallRecording> voiceRecords = {};

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
      originate(channel);
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

void originate(Channel channel) async {
  // var err = holdingBridge.addChannel(channels: [channel.id]);
  // err.then((value) {
  //   var error = holdingBridge.startMoh();
  // });

  bool succeeded = false;

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

  dialed.on('ChannelDestroyed', null, (event, dialedChannel) {
    // print("Dialed Event name: ${event.eventName}");
    // print("Event data: ${event.eventData}");
    // print("Event sender: ${event.sender}");
    // print("");
    //print('Dialed ${dialedChannel.id} destroyed');
    //safeHangup(channel);
    client.externalMediaDelete(externalChannel.id);

    if (succeeded) {
      channel.continueInDialplan(
          context: 'call-rating', priority: 1, extension: 's');
    } else {
      channel.continueInDialplan(context: 'IVR-15', priority: 1);
    }
  });

  channel.on('ChannelDestroyed', null, (event, dialedChannel) {
    // print("Channel Event name: ${event.eventName}");
    // print("Event data: ${event.eventData}");
    // print("Event sender: ${event.sender}");
    // print("");

    voiceRecords.remove(channel.id);
  });

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
    addChannelsToExistingBridge(externalChannel, mixingBridge);
    // //addChannelsToExistingBridge(externalChannel, mixingBridge);
  });

  dialed.on('ChannelStateChange', null, (event, dialedChannel) {
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
    }
  });

  client.statisChannels[channel.id]!.on('StasisEnd', null,
      (event, channelOriginating) {
    // print("Channel Event name: ${event.eventName}");
    // print("Event data: ${event.eventData}");
    // print("Event sender: ${event.sender}");
    // print("");
    //stasisStart(event.eventData as StasisStart, event.sender as Channel);
    // print('Channel ${channelOriginating.name} has exited our application');
    safeHangup(dialed);
    client.externalMediaDelete(externalChannel.id);

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

    client.statisChannels.remove(channel.id);
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
          StasisStart stasisStartEvent = StasisStart.fromJson(data);
          Channel channel = stasisStartEvent.channel;
          if (client.statisChannels[channel.id] != null) {
            client.statisChannels[channel.id]!
                .emit(data['type'], channel, stasisStartEvent);
          } else {
            client.statisChannels[channel.id] = channel;
          }

          client.emit(data['type'], channel, stasisStartEvent);
        }
      case 'StasisEnd':
        {
          StasisEnd stasisEndEvent = StasisEnd.fromJson(data);
          Channel channel = stasisEndEvent.channel;

          if (client.statisChannels[channel.id] != null) {
            print("Emmitting stasis end event: ${data['type']}");
            print("");
            client.statisChannels[channel.id]!
                .emit('StasisEnd', channel, stasisEndEvent);
          } else {
            client.statisChannels[channel.id] = channel;
          }

          client.emit(data['type'], channel, stasisEndEvent);
        }
      case 'ChannelDestroyed':
        {
          ChannelDestroyed channelDestroyedEvent =
              ChannelDestroyed.fromJson(data);
          Channel channel = Channel.fromJson(data['channel']);

          if (client.statisChannels[channel.id] != null) {
            client.statisChannels[channel.id]!
                .emit(data['type'], channel, channelDestroyedEvent);
          } else {
            client.statisChannels[channel.id] = channel;
          }

          client.emit(data['type'], channel, channelDestroyedEvent);
        }
      case 'ChannelStateChange':
        {
          ChannelStateChange channelStateChangeEvent =
              ChannelStateChange.fromJson(data);
          Channel channel = Channel.fromJson(data['channel']);

          if (client.statisChannels[channel.id] != null) {
            client.statisChannels[channel.id]!
                .emit(data['type'], channel, channelStateChangeEvent);
          } else {
            client.statisChannels[channel.id] = channel;
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
  });
  print("Connected to asterisk...");
}
