//npx ts-node src/examples/callbacks/app-ivr.ts

// TypeScript callback version of example published on project https://github.com/asterisk/node-ari-client.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_ari_proxy/ari_client.dart';
import 'package:dart_ari_proxy/ari_client/PlaybackApi.dart';
import 'package:dart_ari_proxy/ari_client/events/stasis_start.dart';
import 'package:dotenv/dotenv.dart';

import '../ari_client/dashboard_client.dart';
import '../ari_client/events/channel_dtmf_received.dart';
import '../ari_client/events/stasis_end.dart';
import '../ari_client/misc.dart';
import '../ari_http_proxy.dart';
import '../globals.dart';

import 'package:uuid/uuid.dart';

Map<String, Timer> timers = {};

class Extension {
  Extension(this.context, this.priority, this.extension);
  String context; //: string;
  String priority; //: string;
  String extension; //: string;
}

class IvrState {
  IvrState();
  String? currentSound; //: menu.sounds[0],
  Playback? currentPlayback; //: client.playback(),
  bool done = false;
}

Map<String, Extension> destinations = {}; // = {};
// 1:{ context: 'call-rating', priority: 1, extension: 's' },
// 2:{ context: 'call-rating', priority: 1, extension: 's' },
// 3:{ context: 'call-rating', priority: 1, extension: 's' },
// 4:{ context: 'call-rating', priority: 1, extension: 's' },
// 5:{ context: 'call-rating', priority: 1, extension: 's' },
// 6:{ context: 'call-rating', priority: 1, extension: 's' },
// 7:{ context: 'call-rating', priority: 1, extension: 's' },
// 8:{ context: 'call-rating', priority: 1, extension: 's' },
// 9:{ context: 'call-rating', priority: 1, extension: 's' }

Ari client = Ari();

//Ari.connect(url, username, password, (err, client) => {
//if (err) {
//  console.log(err);
// return debug(err);
//}
//debug(`Connected to ${url}`);
//console.log(`connected to ${url}`);

var menu = (
  // valid menu options
  options: [1, 2, 3, 4, 5, 6, 7, 8, 9],
  // note: this uses the 'extra' sounds package
  sounds: ['sound:welcome', 'sound:main_menu'],
);

// use once to start the application

// handler for StasisStart event
void stasisStart(StasisStart event, Channel channel) {
  // ensure the channel is not a dialed channel
  print('Channel ${channel.name} has entered the application');

  channel.on('ChannelDtmfReceived', (event, channel) {
    dtmfReceived(event, channel);
  });

  channel.answer((err) {
    if (err) {
      throw err;
    }

    playIntroMenu(channel);
  });
}

// Handler for StasisEnd event
void stasisEnd(StasisEnd event, Channel channel) {
  print('Channel ${channel.name} has left the application');

  // clean up listeners
  // channel.removeListener('ChannelDtmfReceived', (event, channel) {
  //   dtmfReceived(event, channel);
  // });
  cancelTimeout(channel);
}

// Main DTMF handler
void dtmfReceived(ChannelDtmfReceived event, Channel channel) {
  cancelTimeout(channel);
  var digit = int.parse(event.digit);

  print('Channel ${channel.name} entered ${digit}');

  // will be non-zero if valid
  var valid = menu.options.contains(digit);
  if (valid) {
    handleDtmf(channel, event.digit);
  } else {
    print('Channel ${channel.name} entered an invalid option!');

    var play = client.playback();

    channel.play(play, (err, playback) {
      if (err) {
        throw err;
      }

      playIntroMenu(channel);
    }, media: ['sound:option-is-invalid']);
  }
}

void playIntroMenu(Channel channel) {
  IvrState state = IvrState();

  state.currentSound = menu.sounds[0];
  state.currentPlayback = client.playback();
  state.done = false;

  // plays are-you-still-there and restarts the menu
  void stillThere() {
    print('Channel ${channel.name} stopped paying attention...');
    var playback = client.playback();
    channel.play(playback, (err, playback) {
      if (err) {
        throw err;
      }

      playIntroMenu(channel);
    }, media: ['sound:are-you-still-there']);
  }

  // Start up the next sound and handle whatever happens
  void queueUpSound() {
    if (!state.done) {
      // have we played all sounds in the menu?
      if (state.currentSound != null) {
        var timer = setTimeout(stillThere, 10 * 1000);

        timers[channel.id] = timer;
      } else {
        var playback = client.playback();
        state.currentPlayback = playback;

        channel.play(playback, (err, playback) {
          // ignore errors
        }, media: [state.currentSound!]);
        playback.on('PlaybackFinished', (event, playback) {
          queueUpSound();
        });

        var nextSoundIndex = menu.sounds.indexOf(state.currentSound!) + 1;
        state.currentSound = menu.sounds[nextSoundIndex];
      }
    }
  }

  void cancelMenu() {
    state.done = true;
    if (state.currentPlayback != null) {
      state.currentPlayback!.stop((err) {
        // ignore errors
      });
    }

    // remove listeners as future calls to playIntroMenu will create new ones
    channel.removeListener('ChannelDtmfReceived', (event, channel) {
      //cancelMenu();
    });
    channel.removeListener('StasisEnd', (event, channel) {
      //cancelMenu();
    });
  }

  channel.on('ChannelDtmfReceived', (event, channel) {
    cancelMenu();
  });
  channel.on('StasisEnd', (event, channel) {
    cancelMenu();
  });
  queueUpSound();

  // Cancel the menu, as the user did something

  // Cancel the timeout for the channel
  void cancelTimeout(Channel channel) {
    var timer = timers[channel.id];

    if (timer != null) {
      clearTimeout(timer);
      timers.remove(channel.id);
    }
  }
}

// Cancel the timeout for the channel
void cancelTimeout(Channel channel) {
  var timer = timers[channel.id];

  if (timer != null) {
    clearTimeout(timer);
    timers.remove(channel.id);
  }
}

// Handler for channel pressing valid option
void handleDtmf(Channel channel, String digit) {
  // var parts = ['sound:you-entered', util.format('digits:%s', digit)];
  // var done = 0;

  // var playback = client.Playback();
  // channel.play({media: 'sound:you-entered'}, playback, function(err) {
  // // ignore errors
  // channel.play({media: util.format('digits:%s', digit)},playback, function(err) {
  // // ignore errors
  // playIntroMenu(channel);
  // });
  // });
  var intDigit = int.parse(digit);
  //console.log(destinations[digit]);
  channel.continueInDialplan((err) {
    //if (err) safeHangup(channel);
  },
      context: destinations[digit]?.context,
      priority: intDigit,
      extension: destinations[digit]?.extension);
}

//client.on('StasisStart', (event, channel) {
// incoming.answer(err => {
// if (err) { debug('incoming.answer error:', err);
// console.log(`Error: ${err}`);
// }
// getOrCreateHoldingBridge(incoming);
// });
// var cdr: Cdr = {};
// cdr.calldate = event.timestamp;
// cdr.accountcode = event.channel.accountcode;
// cdr.clid = event.channel.caller;
// cdr.channel = event.channel.id;
// cdr.src = event.channel.caller.number;

//stasisStart(event, channel, cdr);
//});

//client.on('StasisEnd', (event, incoming) {
// incoming.answer(err => {
// if (err) { debug('incoming.answer error:', err);
// console.log(`Error: ${err}`);
// }
// getOrCreateHoldingBridge(incoming);
// });
// var cdr: Cdr = {};
// cdr.calldate = event.timestamp;
// cdr.accountcode = event.channel.accountcode;
// cdr.clid = event.channel.caller;
// cdr.channel = event.channel.id;
// cdr.src = event.channel.caller.number;

// stasisEnd(event, incoming);
//});
// can also use client.start(['app-name'...]) to start multiple applications
//client.start('hello');
//});

void app_ivr(List<String> arguments) async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  //rtpIp = env['RTP_ADDRESS']!;
  //port = int.parse(env['RTP_PORT']!);
  //print("Listening on: $rtpIp:$port");
  destinations['1'] = Extension('custom-contexts', '1', 'cc-3');

  destinations['2'] = Extension('custom-contexts', '1', 'cc-7');

  destinations['3'] = Extension('app-ivr', '1', 'IVR-12');

  destinations['4'] = Extension('custom-contexts', '1', 'cc-6');

  destinations['5'] = Extension('app-ivr', '1', 'IVR-13');

  destinations['6'] = Extension('app-ivr', '1', 'IVR-11');

  destinations['7'] = Extension('custom-contexts', '1', 'cc-17');

  destinations['8'] = Extension('custom-contexts', '1', 'cc-21');

  destinations['9'] = Extension('custom-contexts', '1', 'cc-16');

  String wsIp = env['WS_SERVER_ADDRESS']!;
  int wsPort = int.parse(env['WS_SERVER_PORT']!);
  String redisIp = env['REDIS_ADDRESS']!;
  int redisPort = int.parse(env['REDIS_PORT']!);
  String redisPassword = env['REDIS_PASSWORD']!;

  //endpoint = env['PHONE_ENDPOINT']!;
  //print("Endpoint: $endpoint");
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

  client.on('StasisEnd', (event, incoming) {
    // incoming.answer(err => {
    // if (err) { debug('incoming.answer error:', err);
    // console.log(`Error: ${err}`);
    // }
    // getOrCreateHoldingBridge(incoming);
    // });
    // var cdr: Cdr = {};
    // cdr.calldate = event.timestamp;
    // cdr.accountcode = event.channel.accountcode;
    // cdr.clid = event.channel.caller;
    // cdr.channel = event.channel.id;
    // cdr.src = event.channel.caller.number;

    stasisEnd(event, incoming);
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
