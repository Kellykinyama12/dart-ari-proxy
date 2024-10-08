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
//import 'package:eventify/eventify.dart';
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

// CallQueue callQueue = CallQueue(agent_nums);
//CallQueue callQueue = CallQueue(['SIP/7000/1057', 'SIP/7000/3332']);
//CallQueue callQueue = CallQueue(['SIP/7000/1016', 'SIP/7000/1057']);
CallQueue callQueue = CallQueue(['SIP/7000/1057']);
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
  //Channel channel = event.channel;
  if (channel.name.contains('UnicastRTP')) {
    //print('Channel ${channel.name} has entered our application');
    dialed = true;
  }

  if (!dialed) {
    //throw variable;
    var resp = channel.answer();
    resp.then((err) async {
      //print('Channel ${channel.name} has entered our application');
      client.incomingChannels[channel.id] = channel;
      var playback = client.playback();
      //state.currentPlayback = playback;
      bool error = false;

      // channel.play(playback, (err, playback) {
      //   // ignore errors
      // }, media: ['sound:queue-callswaiting']);

      originate(channel, playback);
    });
  } else {
    if (event.args.length > 0 && event.args[0] == 'dialed') {
      client.dialedChannels[channel.id] = channel;
    }
  }
}

void addChannelsToExistingBridge(Channel externalChannel, Bridge mixingBridge) {
  var error = mixingBridge.addChannel(channels: [externalChannel.id]);

  error.then((err) {
    if (err) {
      throw err;
    }
  });
}

void originate(Channel channel, Playback playback) async {
  // if (callTimers[channel.id] != null) {
  //   callTimers[channel.id]!.cancel();
  // }
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

  if (agent.state == AgentState.UNKNOWN) {
    // print(
    //     "Uncreasing unknown agent state to: ${agent.statistics.unknownStateCallsTried}");
    agent.statistics.unknownStateCallsTried++;
  }

  var dialed = await client.channel(endpoint: agent.endpoint);

  Channel? // = await client.externalMedia(

      externalChannel = await client.externalMedia(
    (err, externalChannel) {
      if (err) throw err;
    },
    app: 'hello',
    variables: {'CALLERID(name)': endpoint, 'recording': 'yes'},
    external_host: '$recorderIp:$rtpport',
    format: 'alaw',
  );

  dialed.on('StasisStart', (event) {
    print('Dialed ${dialed.id} entered stasis application');

    joinMixingBridge(channel, dialed, mixingBridge);
  });

  //dialedChannelStateChange =
  dialed.on('ChannelStateChange', (event) {
    //  print('Dialed status to: ${event.channel.state}');
    var (channelStateChangeEvent, dialChannel) =
        event as (ChannelStateChange, Channel);
    //Channel ch = csc.channel as Channel;
    if (dialChannel.state == 'Up') {
      succeeded = true;

      //print('Dialed status to: ${dialChannel.state}');

      voiceRecords[channel.id] = CallRecording(
          file_name: filename,
          file_path: filename,
          agent_number: endpoint,
          phone_number: channel.caller.number);

      //print("Initialised the recording: ${voiceRecords[channel.id]}");

      agent.statistics.answereCalls++;
      agent.status = AgentState.ONCONVERSATION;
      //playback.stop((callback) {});

      addChannelsToExistingBridge(externalChannel, mixingBridge);
    }

    if (dialChannel.state == 'Ringing') {
      // print('Dialed status to: ${dialChannel.state}');
      // print("Agent status changed to state: ${AgentState.LOGGEDIN}");
      agent.state = AgentState.LOGGEDIN;
      agent.statistics.receivedCalls++;
    }
  });

  channel.on('StasisEnd', (event) {
    var (stasisEndEvent, incoming) = event as (StasisEnd, Channel);

    //print('Channel ${incoming.name} has exited our application');
    safeHangup(dialed);

    client.externalMediaDelete(externalChannel.id);

    if (dsbClient != null) {
      if (voiceRecords[channel.id] != null) {
        voiceRecords[channel.id]!.duration_number =
            stasisEndEvent.timestamp.toString();
        // print("Sending recording details to the dashboar");
        dsbClient!.send_call_records(voiceRecords[channel.id]!);
        voiceRecords.remove(channel.id);
      }
    }

    dialed.off();
    channel.off();
  });

  //dialedChannelDestroyed =
  dialed.on('ChannelDestroyed', (event) {
    var (channelDestroyedEvent, dialedChannel) =
        event as (ChannelDestroyed, Channel);

    print('Channel ${dialedChannel.name} has been destroyed');
    // if (externalChannel != null) {
    //   client.externalMediaDelete(externalChannel!.id);
    // }

    if (succeeded) {
      if (dsbClient != null) {
        if (voiceRecords[channel.id] != null) {
          voiceRecords[channel.id]!.duration_number =
              channelDestroyedEvent.timestamp.toString();
          // print("Sending recording details to the dashboar");
          dsbClient!.send_call_records(voiceRecords[channel.id]!);
          voiceRecords.remove(channel.id);
        }
      }

      dialed.off();
      channel.off();

      channel.continueInDialplan(
          context: 'call-rating', priority: 1, extension: 's');

      agent.status = AgentState.IDLE;
    } else {
      print("Call failed");
      dialed.off();
      channel.off();
      channel.continueInDialplan(context: 'IVR-15', priority: 1);
       callTimers[channel.id] = setTimeout(() {
      //   dialed.off();
      //   channel.off();

      //   originate(channel, playback);
      // }, 10000);
    }
  });

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
  dialed.on('StasisEnd', (event) {
    dialedExit(channel, mixingBridge);
  });

  var resp = dialed.answer();
  resp.then((value) {
    moveToMixingBridge(channel, dialed, mixingBridge);
  });
}

void moveToMixingBridge(Channel channel, Channel dialed, Bridge mixingBridge) {
  // print(
  //     'Adding channel ${channel.name} and dialed channel ${dialed.name} to bridge ${mixingBridge.id}');

  mixingBridge.addChannel(channels: [channel.id, dialed.id]);
}

dialedExit(Channel dialed, Bridge mixingBridge) {
  // print(
  //     'Dialed channel ${dialed.name} has left our application, destroying mixing bridge ${mixingBridge.id}');

  mixingBridge.destroy((err) {
    if (err) {
      throw err;
    }

    dialed.hangup((err) => {});
  });
}

void safeHangup(Channel channel) {
  //print('Hanging up channel ${channel.name}');

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

  client.on("StasisStart", (event) {
    var (stasisStartEvent, channel) = (event) as (StasisStart, Channel);

    stasisStart(stasisStartEvent, channel);
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
            client.statisChannels[channel.id]!.emit(data['type'],
                (stasisStartEvent, client.statisChannels[channel.id]));
          } else {
            client.statisChannels[channel.id] = channel;
            client.statisChannels[channel.id]!.emit(data['type'],
                (stasisStartEvent, client.statisChannels[channel.id]));
          }

          //channel.stasisStart(stasisStartEvent, channel);

          //client.emit(data['type'], stasisStartEvent);
          client.stasisStart(stasisStartEvent, channel);
        }
      case 'StasisEnd':
        {
          StasisEnd stasisEndEvent = StasisEnd.fromJson(data,
              channel: client.statisChannels[data['channel']['id']]);
          Channel channel = stasisEndEvent.channel;

          if (client.statisChannels[channel.id] != null) {
            //print("Emmitting stasis end event: ${data['type']}");
            client.statisChannels[channel.id]!.emit('StasisEnd',
                (stasisEndEvent, client.statisChannels[channel.id]));
          } else {
            client.statisChannels[channel.id] = channel;
            client.statisChannels[channel.id]!.emit(data['type'],
                (stasisEndEvent, client.statisChannels[channel.id]));
          }

          //channel.stasisEnd(stasisEndEvent, channel);

          client.emit(data['type'], (stasisEndEvent, channel));
        }
      case 'ChannelDestroyed':
        {
          ChannelDestroyed channelDestroyedEvent = ChannelDestroyed.fromJson(
              data,
              channel: client.statisChannels[data['channel']['id']]);
          Channel channel = channelDestroyedEvent.channel;

          //print("channel ${channel.id} destroyed");

          if (client.statisChannels[channel.id] != null) {
            client.statisChannels[channel.id]!.emit(data['type'],
                (channelDestroyedEvent, client.statisChannels[channel.id]!));
          } else {
            client.statisChannels[channel.id] = channel;
            client.statisChannels[channel.id]!.emit(data['type'],
                (channelDestroyedEvent, client.statisChannels[channel.id]!));
          }

          //channel.channelDestroyed(channelDestroyedEvent, channel);

          // client.emit(data['type'], channel, channelDestroyedEvent);

          //client.channelDestroyed(channelDestroyedEvent);

          //client.channelDestroyed(channelDestroyedEvent, channel);

          client.emit(data['type'], (channelDestroyedEvent, channel));
        }
      case 'ChannelStateChange':
        {
          ChannelStateChange channelStateChangeEvent =
              ChannelStateChange.fromJson(data,
                  channel: client.statisChannels[data['channel']['id']]);
          Channel channel = channelStateChangeEvent.channel;

          if (client.statisChannels[channel.id] != null) {
            // client.statisChannels[channel.id]!
            //     .emit(data['type'], channelStateChangeEvent);
          } else {
            client.statisChannels[channel.id] = channel;
            // client.statisChannels[channel.id]!
            //     .emit(data['type'], channelStateChangeEvent);
          }
          channel.channelStateChange(channelStateChangeEvent, channel);

          //client.channelStateChange(channelStateChangeEvent);
          //client.channelStateChange(channelStateChangeEvent, channel);

          client.emit(data['type'], (channelStateChangeEvent, channel));
        }

      case 'ChannelDtmfReceived':
        {
          ChannelDtmfReceived channelDtmfReceivedEvent =
              ChannelDtmfReceived.fromJson(data);
          Channel channel = Channel.fromJson(data['channel']);

          if (client.statisChannels[channel.id] != null) {
            client.statisChannels[channel.id]!
                .emit(data['type'], channelDtmfReceivedEvent);
          } else {
            client.statisChannels[channel.id] = channel;
            client.statisChannels[channel.id]!
                .emit(data['type'], channelDtmfReceivedEvent);
          }
          client.emit(data['type'], (channelDtmfReceivedEvent, channel));
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
          client.emit(data['type'], playbackFinished);
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
  });
  print("Connected to asterisk...");
}
