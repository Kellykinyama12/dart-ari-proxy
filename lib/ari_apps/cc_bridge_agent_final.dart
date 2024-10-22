import 'dart:async';
import 'dart:convert';
import 'dart:io';

//import 'package:dart_ari_proxy/ari_apps/bridge_dial.dart';
import 'package:dart_ari_proxy/ari_apps/call_queue/agents.dart';
import 'package:dart_ari_proxy/ari_apps/db_queries.dart';
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

HttpClient httpRtpClient = HttpClient();
Future<int?> rtpPort(String filename) async {
  var uri = Uri(
      scheme: "http",
      userInfo: "",
      host: voiceLoggerIp,
      port: voiceLoggerPort,
      query: "",
      queryParameters: {'filename': filename});
  try {
    HttpClientRequest request = await httpRtpClient.postUrl(uri);
    HttpClientResponse response = await request.close();
    //print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    var port = jsonDecode(stringData); //print(stringData);
    return port['rtp_port'];
  } catch (e) {
    print("Error: $e");
  }
}

Ari client = Ari();

Map<String, CallRecording> voiceRecords = {};
Map<String, bool> succeededCalls = {};
Map<String, Timer> callTimers = {};

Map<String, int> dialChannelStateChangeListeners = {};

Map<String, int> incomingStasisEndListeners = {};

Map<String, int> dialedChannelDestroyedListeners = {};

Map<String, int> dialedStasisStartListeners = {};

Map<String, int> dialedStasisEndListeners = {};

stasisStart(StasisStart event, Channel channel) async {
  bool dialed = event.args.length > 0 ? event.args[0] == 'dialed' : false;
  if (channel.name.contains('UnicastRTP')) {
    dialed = true;
  }

  if (!dialed) {
    //throw variable;
    await channel.answer();

    succeededCalls[channel.id] = false;

    Playback playback = client.playback();
    await channel.play(playback, media: ['sound:vm-dialout']);

    //const oneSec = Duration(seconds: 3);
    // Timer.periodic(oneSec, (Timer t) {
    //   callTimers[channel.id] = t;
    //   channel.off();
    await originate(channel);
    // });
  } else {
    if (event.args.length > 0 && event.args[0] == 'dialed') {}
  }
}

Future<void> originate(Channel incoming) async {
  Uuid uid = Uuid();
  String filename = uid.v1();

  Agent? agent = await callQueue.nextAgentV2(incoming.id);

  if (agent != null) {
    callQueue.agentsAnswered[agent.endpoint] = agent;
  }

  agent?.statistics.unknownStateCallsTried++;
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

  int? rtpport = await rtpPort(filename);
  var dialed = await client.channel(endpoint: endpoint);

  Channel externalChannel;

  if (!incoming.listeners.contains('StasisEnd')) {
    incoming.on('StasisEnd', (event) async {
      var (stasisEndEvent, channel) = event as (StasisEnd, Channel);

      // if (incomingStasisEndListeners[incoming.id] == null) {
      //   incomingStasisEndListeners[incoming.id] = 1;
      // } else {
      //   throw "Incoming channel: ${incoming.id} is already listening to StasisEnd event";
      // }

      print("Incoming channel: ${incoming.id} exited our apllication");
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
          //agent.status = AgentState.IDLE;
        }, 30000);
      } else {}
      // callQueue.incomingAcdToAgents.remove(incoming.id);
    });
  }

  if (!dialed.listeners.contains('ChannelStateChange')) {
    dialed.on('ChannelStateChange', (event) {
      var (channelStateChangeEvent, dialChannel) =
          event as (ChannelStateChange, Channel);
      print('Dialed status to: ${dialChannel.state}');

      // if (dialChannelStateChangeListeners[incoming.id] == null) {
      //   dialChannelStateChangeListeners[incoming.id] = 1;
      // } else {
      //   throw "Dialed channel: ${dialChannel.id} is already listening to ChannelStateChange event";
      // }
      if (dialChannel.state == 'Up') {
        voiceRecords[incoming.id] = CallRecording(
          file_name: filename,
          file_path: filename,
          agent_number: endpoint,
          phone_number: incoming.caller.number,
          answerdate: channelStateChangeEvent.timestamp.toString(),
          src: incoming.caller.number,
          dst: agent.endpoint,
          clid: incoming.caller.number,
        );
        agent.statistics.answereCalls++;
        agent.status = AgentState.ONCONVERSATION;
        DbQueries.updateAgentStatus(
            agent.endpoint, agent.state.toString(), agent.status.toString());
        print("Removing timer ...");
        callTimers.remove(incoming.id);
        succeededCalls[incoming.id] = true;
        //}
      }

      if (dialChannel.state == 'Ringing') {
        agent.status = AgentState.RINGING;
        DbQueries.updateAgentStatus(
            agent.endpoint, agent.state.toString(), agent.status.toString());

        //callQueue.agentsLogged[agent.endpoint] = agent;
        agent.statistics.receivedCalls++;

        if (callTimers[incoming.id] != null) {
          callTimers[incoming.id]!.cancel();
        }
      }
    });
  }

  if (!dialed.listeners.contains('ChannelDestroyed')) {
    dialed.on('ChannelDestroyed', (event) async {
      var (channelDestroyedEvent, channel) =
          event as (ChannelDestroyed, Channel);

      // if (dialedChannelDestroyedListeners[incoming.id] == null) {
      //   dialedChannelDestroyedListeners[incoming.id] = 1;
      // } else {
      //   throw "Dialed channel: ${channel.id} is already listening to ChannelDestroyed event";
      // }

      if (succeededCalls[incoming.id] == true) {
        await incoming.continueInDialplan(
            context: 'call-rating', priority: 1, extension: 's');

        if (voiceRecords[incoming.id] != null) {
          voiceRecords[incoming.id]!.duration_number =
              channelDestroyedEvent.timestamp.toString();
          voiceRecords[incoming.id]!.hangupdate =
              channelDestroyedEvent.timestamp.toString();
          voiceRecords.remove(incoming.id);
        }

        if (agent.status == AgentState.ONCONVERSATION) {
          setTimeout(() {
            print("setting agent state: to idle");
            agent.status = AgentState.IDLE;
            DbQueries.updateAgentStatus(agent.endpoint, agent.state.toString(),
                agent.status.toString());
          }, 30000);
        } else {}
      }
    });
  }

  if (!dialed.listeners.contains('StasisStart')) {
    dialed.on('StasisStart', (event) async {
      // if (dialedStasisStartListeners[incoming.id] == null) {
      //   dialedStasisStartListeners[incoming.id] = 1;
      // } else {
      //   throw "Dialed channel: ${dialed.id} is already listening to ChannelDestroyed event";
      // }

      Bridge mixingBridge = await client.bridge(type: ['mixing']);

      if (!dialed.listeners.contains('StasisEnd')) {
        dialed.on('StasisEnd', (event) async {
          var (stasisEndEvent, channel) = event as (StasisEnd, Channel);

          // if (dialedStasisEndListeners[incoming.id] == null) {
          //   dialedStasisEndListeners[incoming.id] = 1;
          // } else {
          //   throw "Dialed channel: ${dialed.id} is already listening to StasisEnd event";
          // }
          if (succeededCalls[incoming.id] == true) {
            await incoming.continueInDialplan(
                context: 'call-rating', priority: 1, extension: 's');

            if (voiceRecords[incoming.id] != null) {
              voiceRecords[incoming.id]!.duration_number =
                  stasisEndEvent.timestamp.toString();

              voiceRecords[incoming.id]!.hangupdate =
                  stasisEndEvent.timestamp.toString();
              await voiceRecords[incoming.id]!.insertCallRecording();
              agent.waitingSince = DateTime.now();
              voiceRecords.remove(incoming.id);
            }
          }

          await mixingBridge.destroy();

          if (agent.status == AgentState.ONCONVERSATION) {
            setTimeout(() {
              print("setting agent state: to idle");
              agent.status = AgentState.IDLE;
              DbQueries.updateAgentStatus(agent.endpoint,
                  agent.state.toString(), agent.status.toString());
            }, 30000);
          } else {
            // agent.status = AgentState.IDLE;
          }
        });
      }

      await dialed.answer();

      if (rtpport != null) {
        externalChannel = await client.externalMedia(
          (err, externalChannel) {
            if (err) throw err;
          },
          app: 'hello',
          variables: {'CALLERID(name)': agent.endpoint, 'recording': 'yes'},
          external_host: '$voiceLoggerIp:$rtpport',
          format: 'alaw',
        );

        // //final mixingBridge = await bridge.create(type: ['mixing']);
        await mixingBridge
            .addChannel(channels: [incoming.id, dialed.id, externalChannel.id]);
      } else {
        await mixingBridge.addChannel(channels: [incoming.id, dialed.id]);
      }
    });
  }

  await dialed.originate(
      // endpoint: next_agent.number,
      endpoint: endpoint,
      app: 'hello',
      appArgs: ['dialed', agent.endpoint, incoming.id],
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

  ws.listen((event) async {
    await redisCmd.send_object(["PUBLISH", "monkey", event]);
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

          await redisCmd.send_object(
              ["PUBLISH", "monkey", jsonEncode(client.statisChannels)]);

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
          final jsonData = jsonEncode(client.statisChannels);
          //print("Channels: $jsonData");
          await redisCmd.send_object(["PUBLISH", "monkey", jsonData]);

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
          final jsonData = jsonEncode(client.statisChannels);
          //print("Channels: $jsonData");
          await redisCmd.send_object(["PUBLISH", "monkey", jsonData]);

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

          final jsonData = jsonEncode(client.statisChannels);
          //print("Channels: $jsonData");
          await redisCmd.send_object(["PUBLISH", "monkey", jsonData]);

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
