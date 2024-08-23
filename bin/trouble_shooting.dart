import 'dart:convert';
import 'dart:io';

//import 'package:dart_ari_proxy/ari_apps/app_ivr.dart';
import 'package:dart_ari_proxy/ari_client.dart';

//import 'package:dart_ari_proxy/ari_client/models.dart';
Ari client = Ari();
void main() async {
  //recorderIp = env['HTTP_SERVER_ADDRESS']!;
  //recorderPort = int.parse(env['HTTP_SERVER_PORT']!);
  // WebSocket ws = await client.connect();

  ChannelsApi.list().then((response) {
    var channels = jsonDecode(response.resp);
    print("Channel count: ${channels.length}");
  });

  // client.on("StasisStart", (event, incoming) {
  //   //print(event);
  //   stasisStart(event, incoming);
  // });

  // ws.listen((event) {
  //   var e = json.decode(event);
  //   //print(e['type']);
  //   client.emit(e);

  //   // Function? func = app[e['type']];
  //   // func!.call(e);
  // });
  print("Connected to asterisk...");
}
