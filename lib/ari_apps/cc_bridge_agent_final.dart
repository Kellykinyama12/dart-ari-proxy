import 'dart:async';
import 'dart:convert';
import 'dart:io';

//import 'package:dart_ari_proxy/ari_apps/bridge_dial.dart';
import 'package:dart_ari_proxy/ari_apps/call_queue/agents.dart';
import 'package:dart_ari_proxy/ari_apps/call_queue/call_queue.dart';
import 'package:dart_ari_proxy/ari_client.dart';
import 'package:dart_ari_proxy/ari_client/BridgesApi.dart';
import 'package:dart_ari_proxy/ari_client/PlaybackApi.dart';
import 'package:dart_ari_proxy/ari_client/cdr.dart';
import 'package:dart_ari_proxy/ari_client/dashboard_client.dart';
import 'package:dart_ari_proxy/ari_client/events/channel_destroyed.dart';
import 'package:dart_ari_proxy/ari_client/events/channel_dtmf_received.dart';
import 'package:dart_ari_proxy/ari_client/events/channel_state_change.dart';
import 'package:dart_ari_proxy/ari_client/events/playback_finished.dart';
import 'package:dart_ari_proxy/ari_client/events/stasis_end.dart';
import 'package:dart_ari_proxy/ari_client/events/stasis_start.dart';
import 'package:dart_ari_proxy/ari_client/misc.dart';
import 'package:dart_ari_proxy/globals.dart';
import 'package:dotenv/dotenv.dart';
import 'package:uuid/uuid.dart';

String recorderIp = "10.43.0.55";
HttpClient httpRtpClient = HttpClient();
//import 'package:events_emitter/listener.dart';
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

Ari client = Ari();
//CallQueue callQueue = CallQueue(agent_nums);
//CallQueue callQueue = CallQueue(['SIP/7000/1057', 'SIP/7000/3332']);

//8940/1020/
//CallQueue callQueue = CallQueue(['SIP/7000/1016', 'SIP/7000/1057']);
//CallQueue callQueue = CallQueue();

Map<String, CallRecording> voiceRecords = {};
Map<String, bool> succeededCalls = {};
Map<String, Timer> callTimers = {};

stasisStart(StasisStart event, Channel channel) async {
  bool dialed = event.args.length > 0 ? event.args[0] == 'dialed' : false;
  //Channel channel = event.channel;
  if (channel.name.contains('UnicastRTP')) {
    //print('Channel ${channel.name} has entered our application');
    dialed = true;
  }

  if (!dialed) {
    //throw variable;
    await channel.answer();

    succeededCalls[channel.id] = false;

    //originate(channel);

    // callTimers[channel.id] = setTimeout(() {
    //   print("calling originate");
    //   channel.off();
    //   originate(channel);
    // }, 1000);

    Playback playback = client.playback();
    await channel.play(playback, media: ['sound:vm-dialout']);

    const oneSec = Duration(seconds: 3);
    Timer.periodic(oneSec, (Timer t) {
      callTimers[channel.id] = t;
      originate(channel);
    });
  } else {
    if (event.args.length > 0 && event.args[0] == 'dialed') {}
  }
}

Future<void> originate(Channel incoming) async {
  //const outgoing = client.Channel();

  Uuid uid = Uuid();
  String filename = uid.v1();

  Agent? agent = callQueue.nextAgent();

  print("Agent enpoint: ${agent?.endpoint}");
  print("Agent state: ${agent?.state}");
  print("");

  if (agent == null) {
    await incoming.continueInDialplan(context: 'IVR-15', priority: 1);
    if (callTimers[incoming.id] != null) {
      callTimers[incoming.id]!.cancel();
      callTimers.remove(incoming.id);
    }
    return;
  }
  String endpoint = "SIP/7000/${agent.endpoint}";

  int rtpport = await rtpPort(filename);
  var dialed = await client.channel(endpoint: endpoint);

  incoming.once('StasisEnd', (event) async {
    var (stasisEndEvent, channel) = event as (StasisEnd, Channel);
    //print('incoming.once StasisEnd event:${stasisEndEvent.type}');
    //print('incoming.once StasisEnd channel: ${channel.id}');
    // if (callTimers[incoming.id] != null) {
    //   callTimers[incoming.id]!.cancel();
    //   callTimers.remove(incoming.id);
    // }
    if (callTimers[incoming.id] != null) {
      callTimers[incoming.id]!.cancel();
      callTimers.remove(incoming.id);
    }
    callTimers.remove(incoming.id);
    await dialed.hangup();
    //incoming.off();

    if (agent.status == AgentState.ONCONVERSATION) {
      setTimeout(() {
        print("setting agent state: to idle");
        agent.status = AgentState.IDLE;
      }, 30000);
    } else {
      agent.status = AgentState.IDLE;
    }
  });

  //dialedChannelStateChange =
  dialed.on('ChannelStateChange', (event) {
    var (channelStateChangeEvent, dialChannel) =
        event as (ChannelStateChange, Channel);
    //Channel ch = csc.channel as Channel;
    print('Dialed status to: ${dialChannel.state}');
    if (dialChannel.state == 'Up') {
      //print('Dialed status to: ${dialChannel.state}');

      voiceRecords[incoming.id] = CallRecording(
          file_name: filename,
          file_path: filename,
          agent_number: endpoint,
          phone_number: incoming.caller.number);

      //print("Initialised the recording: ${voiceRecords[channel.id]}");

      agent.statistics.answereCalls++;
      agent.status = AgentState.ONCONVERSATION;
      //playback.stop((callback) {});
      // if (callTimers[incoming.id] != null) {
      //  callTimers[incoming.id]!.cancel();
      print("Removing timer ...");
      callTimers.remove(incoming.id);
      succeededCalls[incoming.id] = true;
      //}
    }

    if (dialChannel.state == 'Ringing') {
      // print('Dialed status to: ${dialChannel.state}');
      // print("Agent status changed to state: ${AgentState.LOGGEDIN}");
      agent.status = AgentState.RINGING;

      callQueue.agentsLogged[agent.endpoint] = agent;
      agent.statistics.receivedCalls++;

      if (callTimers[incoming.id] != null) {
        callTimers[incoming.id]!.cancel();
      }
    }
  });

  dialed.once('ChannelDestroyed', (event) async {
    var (channelDestroyedEvent, channel) = event as (ChannelDestroyed, Channel);
    //print('outgoing.once ChannelDestroyed event:${channelDestroyedEvent.type}');
    //print('outgoing.once ChannelDestroyed channel:${channel.id}');

    //await incoming.hangup();

    if (succeededCalls[incoming.id] == true) {
      //print("Redirecting call");
      await incoming.continueInDialplan(
          context: 'call-rating', priority: 1, extension: 's');

      //   //   if (dsbClient != null) {
      if (voiceRecords[incoming.id] != null) {
        voiceRecords[incoming.id]!.duration_number =
            channelDestroyedEvent.timestamp.toString();
        //print("Sending recording details to the dashboar");
        dsbClient!.send_call_records(voiceRecords[incoming.id]!);
        voiceRecords.remove(incoming.id);
      }

      if (agent.status == AgentState.ONCONVERSATION) {
        setTimeout(() {
          print("setting agent state: to idle");
          agent.status = AgentState.IDLE;
        }, 30000);
      } else {
        agent.status = AgentState.IDLE;
      }
    }
  });

  dialed.once('StasisStart', (event) async {
    var (stasisStartEvent, channel) = event as (StasisStart, Channel);
    //print('outgoing.once StasisStart event:${stasisStartEvent.type}');
    //print('outgoing.once StasisStart outgoing:${channel.id}');

    //const bridge = client.Bridge();
    ///Bridge mixingBridge = await client.bridge(type: ['mixing']);
    Bridge mixingBridge = await client.bridge(type: ['mixing']);

    dialed.once('StasisEnd', (event) async {
      var (stasisEndEvent, channel) = event as (StasisEnd, Channel);
      //print('outgoing.once StasisEnd event:${stasisEndEvent.type}');
      //print('outgoing.once StasisEnd channel:${channel.id}');
      //outgoing.off();
      if (succeededCalls[incoming.id] == true) {
        //print("Redirecting call");
        await incoming.continueInDialplan(
            context: 'call-rating', priority: 1, extension: 's');

        //   //   if (dsbClient != null) {
        if (voiceRecords[incoming.id] != null) {
          voiceRecords[incoming.id]!.duration_number =
              stasisEndEvent.timestamp.toString();
          //print("Sending recording details to the dashboar");
          dsbClient!.send_call_records(voiceRecords[incoming.id]!);
          voiceRecords.remove(incoming.id);
        }
      }

      await mixingBridge.destroy();

      if (agent.status == AgentState.ONCONVERSATION) {
        setTimeout(() {
          print("setting agent state: to idle");
          agent.status = AgentState.IDLE;
        }, 30000);
      } else {
        agent.status = AgentState.IDLE;
      }
    });

    // if (agent.status == AgentState.ONCONVERSATION) {
    //   setTimeout(() {
    //     print("setting agent state: to idle");
    //     agent.status = AgentState.IDLE;
    //   }, 30000);
    // } else {
    //   agent.status = AgentState.IDLE;
    // }

    await dialed.answer();
    Channel externalChannel = await client.externalMedia(
      (err, externalChannel) {
        if (err) throw err;
      },
      app: 'hello',
      variables: {'CALLERID(name)': 'recording', 'recording': 'yes'},
      external_host: '$recorderIp:$rtpport',
      format: 'alaw',
    );
    // //final mixingBridge = await bridge.create(type: ['mixing']);
    await mixingBridge
        .addChannel(channels: [incoming.id, dialed.id, externalChannel.id]);
  });

  //Playback playback = client.playback();
  //await incoming.play(playback, media: ['sound:vm-dialout']);

  // Originate call from incoming channel to endpoint
  // await outgoing.originate({
  //     endpoint: ENDPOINT,
  //     app: appName,
  //     appArgs: 'dialed',
  // });

  if (agent.state == AgentState.UNKNOWN) {
    agent.statistics.unknownStateCallsTried++;
  }

  await dialed.originate(
      // endpoint: next_agent.number,
      endpoint: endpoint,
      app: 'hello',
      appArgs: ['dialed'],
      callerId: incoming.caller.number);
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
