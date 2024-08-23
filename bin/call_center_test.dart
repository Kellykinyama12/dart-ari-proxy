import 'dart:convert';
import 'dart:io';

import 'package:dart_ari_proxy/ari_client.dart';
import 'package:dart_ari_proxy/ari_client/events/stasis_start.dart';
// import 'package:dart_ari_proxy/dart_ari_proxy.dart';
// import 'package:dotenv/dotenv.dart';
// import 'package:test/test.dart';

Ari client = Ari();

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

      originate(channel);
      //getOrCreateHoldingBridge(channel);
    });

    //actveCalls.set(channel.id, channel.id);
    //callsWaiting.set(channel.id, channel.id);

    //errors.set(channel.id, 0);
    //sendCdr();

    //originate(channel);
  }
  // else{
  //   if(event.args.length > 0 && event.args[0] == 'dialed'){

  //   }

  // }
}

void safeHangup(Channel channel) {
  print('Hanging up channel ${channel.name}');

  channel.hangup((err) {
    // ignore error
  });
}

void originate(Channel channel) async {
  // var err = holdingBridge.addChannel(channels: [channel.id]);
  // err.then((value) {
  //   var error = holdingBridge.startMoh();
  // });
  bool succeeded = false;

  var dialed = await client.channel(endpoint: "SIP/7000/1016");
  // var externalChannel = await client.channel(
  //     app: 'hello',
  //     endpoint: endpoint,
  //     variables: {'CALLERID(name)': endpoint, 'recording': 'yes'});

  dialed.on('ChannelDestroyed', (event, dialed) {
    print('Dialed ${dialed.id} destroyed');

    safeHangup(channel);
  });

  dialed.on('StasisStart', (event, dialedChannel) {
    print('Dialed ${dialed.id} entered stasis application');
    //print(event);
    //CallsInConversation.set(channel.id, channel.id);
    //sendCdr();

    //addChannelsToExistingBridge(externalChannel, mixingBridge);
  });

  dialed.on('ChannelStateChange', (event, dialed) {
    print('Dialed status to: ${event.channel.state}');

    if (event.channel.state == 'Up') {
      print('Dialed status to: ${event.channel.state}');
    }
  });

  // dialed.on('StasisEnd', (event, dialChannel) {
  //   print('Channel ${dialChannel.name} has exited our application');
  //   safeHangup(channel);
  // });

  channel.on('StasisEnd', (event, channel) {
    print('Channel ${channel.name} has exited our application');
  });

  //Agent next_agent = callQueue.nextAgent();

  dialed.originate((err, dialed) async {
    if (err) {
      //debug('originate error:', err);
      throw err;
    }
  },
      // endpoint: next_agent.number,
      endpoint: "SIP/7000/1016",
      app: 'hello',
      appArgs: ['dialed'],
      callerId: channel.caller.number);
}

void call_center_bridge(List<String> args) async {
  //var env = DotEnv(includePlatformEnvironment: true)..load();
  //recorderIp = env['HTTP_SERVER_ADDRESS']!;
  //recorderPort = int.parse(env['HTTP_SERVER_PORT']!);

  // String voice_records = env['DASHBOARD_RECORDER_ENDPOINT']!;
  // String cdr_records = env['DASHBOARD_CDR_ENDPOINT']!;

  //dsbClient = DasboardClient(Uri.parse(voice_records), Uri.parse(cdr_records));

  WebSocket ws = await client.connect();

  client.on("StasisStart", (event, incoming) {
    //print(event);
    //stasisStart(event, incoming);
  });

  // client.on("StasisEnd", (event, incoming) {
  //   print(event);
  //   //stasisStart(event, incoming);
  // });

  ws.listen((event) {
    var e = json.decode(event);
    //print(e['type']);
    client.emit(e);

    // Function? func = app[e['type']];
    // func!.call(e);
  });
  print("Connected to asterisk...");
}

void main() {
  call_center_bridge([]);
}
