import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../ari_client.dart';
import '../ari_client/PlaybackApi.dart';
import '../ari_client/events/stasis_end.dart';
import '../ari_client/events/stasis_start.dart';
import '../ari_client/misc.dart';

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

class Menu {
  List<int> options = [1, 2];
  List<String> sounds = ['sound:press-1', 'sound:or', 'sound:press-2'];
}

Menu menu = Menu();

Ari client = Ari();

// Cancel the timeout for the channel
void cancelTimeout(Channel channel) {
  Timer? timer = timers[channel.id];

  if (timer != null) {
    clearTimeout(timer);
    timers.remove(channel.id);
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

      print("Playing intro menu");

      playIntroMenu(channel);
    }, media: ['sound:are-you-still-there']);
  }

  // Start up the next sound and handle whatever happens
  void queueUpSound() {
    if (state.done == false) {
      // have we played all sounds in the menu?
      if (state.currentSound == null) {
        var timer = setTimeout(stillThere, 10 * 1000);

        timers[channel.id] = timer;
      } else {
        var playback = client.playback();
        state.currentPlayback = playback;

        channel.play(playback, (err, playback) {
          // ignore errors
        }, media: [state.currentSound!]);
        playback.on('PlaybackFinished', (event, playback) {
          print("playback finshed");
          queueUpSound();
        });
        print("Playing next sound");
        var nextSoundIndex = menu.sounds.indexOf(state.currentSound!) + 1;
        if (menu.sounds.length > nextSoundIndex) {
          state.currentSound = menu.sounds[nextSoundIndex];
        } else {
          state.currentSound = null;
          //state.done = true;
        }
        print("Current sound: ${state.currentSound}");
      }
    }
  }

  // Cancel the menu, as the user did something
  void cancelMenu() {
    state.done = true;
    if (state.currentPlayback != null) {
      state.currentPlayback!.stop((err) {
        // ignore errors
      });
    }

    // remove listeners as future calls to playIntroMenu will create new ones
    // channel.removeListener('ChannelDtmfReceived', cancelMenu);
    // channel.removeListener('StasisEnd', cancelMenu);
  }

  channel.on('ChannelDtmfReceived', (err, channel) {
    cancelMenu();
  });
  //channel.on('StasisEnd', cancelMenu);
  queueUpSound();
}

// Handler for channel pressing valid option
void handleDtmf(Channel channel, int digit) {
  // var parts = ['sound:you-entered', "digits:${digit.toString()}"];
  // var done = 0;
  cancelTimeout(channel);
  var playback = client.playback();
  //{media: 'sound:you-entered'},
  channel.play(playback, (err, playback) {
    // ignore errors
    channel.play(playback, (err, playback) {
      // ignore errors
      playIntroMenu(channel);
    }, media: ["digits:${digit.toString()}"]);
  }, media: ['sound:you-entered']);
}

// Main DTMF handler
void dtmfReceived(event, channel) {
  cancelTimeout(channel);
  var digit = int.parse(event.digit);

  print('Channel ${channel.name} entered ${digit}');

  // will be non-zero if valid
  //var valid = ~menu.options.indexOf(digit);
  var valid = menu.options.contains(digit);
  if (valid) {
    handleDtmf(channel, digit);
  } else {
    print('Channel ${channel.name} entered an invalid option!');
    var play = client.playback();
    channel.play(play, (err, playback) {
      if (err) {
        throw err;
      }

      //playIntroMenu(channel);
    }, media: ['sound:option-is-invalid']);
  }
}

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

void app_ivr_2(List<String> arguments) async {
  client.on("StasisStart", (event, incoming) {
    //print(event);
    stasisStart(event, incoming);

    // client.on('StasisEnd', (event, incoming) {
    //   stasisEnd(event, incoming);
    // });
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
