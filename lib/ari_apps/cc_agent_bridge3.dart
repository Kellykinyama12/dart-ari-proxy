import 'dart:convert';
import 'dart:io';

import 'package:dart_ari_proxy/ari_client.dart';
import 'package:dart_ari_proxy/ari_client/BridgesApi.dart';
import 'package:dart_ari_proxy/ari_client/PlaybackApi.dart';
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
import 'package:events_emitter/listener.dart';

Ari client = Ari();

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

    originate(channel);
  } else {
    if (event.args.length > 0 && event.args[0] == 'dialed') {}
  }
}

void originate(Channel incoming) async {
  //const outgoing = client.Channel();
  var outgoing = await client.channel(endpoint: 'SIP/7000/1057');

  incoming.once('StasisEnd', (event) async {
    var (stasisEndEvent, channel) = event as (StasisEnd, Channel);
    print('incoming.once StasisEnd event:$stasisEndEvent');
    print('incoming.once StasisEnd channel: $channel');

    await outgoing.hangup();
  });

  outgoing.once('ChannelDestroyed', (event) async {
    var (channelDestroyedEvent, channel) = event as (ChannelDestroyed, Channel);
    print('outgoing.once ChannelDestroyed event:$channelDestroyedEvent');
    print('outgoing.once ChannelDestroyed channel:$channel');

    await incoming.hangup();
  });

  outgoing.once('StasisStart', (event) async {
    var (stasisStartEvent, outgoing) = event as (StasisStart, Channel);
    print('outgoing.once StasisStart event:$stasisStartEvent');
    print('outgoing.once StasisStart outgoing:$outgoing');

    //const bridge = client.Bridge();
    ///Bridge mixingBridge = await client.bridge(type: ['mixing']);
    Bridge mixingBridge = await client.bridge(type: ['mixing']);

    outgoing.once('StasisEnd', (event) async {
      var (stasisEndEvent, channel) = event as (StasisEnd, Channel);
      print('outgoing.once StasisEnd event:$stasisEndEvent');
      print('outgoing.once StasisEnd channel:$channel');

      await mixingBridge.destroy();
    });

    await outgoing.answer();
    //final mixingBridge = await bridge.create(type: ['mixing']);
    await mixingBridge.addChannel(channels: [incoming.id, outgoing.id]);
  });

  Playback playback = client.playback();
  await incoming.play(playback, media: ['sound:vm-dialout']);

  // Originate call from incoming channel to endpoint
  // await outgoing.originate({
  //     endpoint: ENDPOINT,
  //     app: appName,
  //     appArgs: 'dialed',
  // });

  await outgoing.originate(
      // endpoint: next_agent.number,
      endpoint: 'SIP/7000/1057',
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
