//import 'package:dart_ari_proxy/ari_apps/app_ivr.dart';
//import 'package:dart_ari_proxy/ari_apps/app_ivr2.dart';
//import 'package:dart_ari_proxy/ari_apps/bridge_dial.dart';
//import 'package:dart_ari_proxy/ari_apps/bridge_dial2.dart';
//import 'package:dart_ari_proxy/ari_apps/call_center.dart';
//import 'package:dart_ari_proxy/ari_apps/caller_center_queue.dart';
//import 'package:dart_ari_proxy/ari_apps/channel-aa.dart';
//import 'package:dart_ari_proxy/ari_apps/bridge_move.dart';

// import 'package:dart_ari_proxy/ari_apps/call_center_bridge.dart';
// import 'package:dart_ari_proxy/ari_apps/cc_bridge_agent.dart';
//import 'package:dart_ari_proxy/ari_apps/cc_agent_bridge3.dart';
//import 'package:dart_ari_proxy/ari_apps/call_center_bridge.dart';
import 'package:dart_ari_proxy/ari_apps/call_queue/call_queue.dart';
import 'package:dart_ari_proxy/ari_apps/cc_bridge_agent_final.dart';
import 'package:dart_ari_proxy/globals.dart';
import 'package:dotenv/dotenv.dart';

void main(List<String> arguments) async {
  //call_center_queue(arguments);
  //call_center(arguments);
  //app_ivr(arguments);
  //app_ivr_2(arguments);
  //bridge_dial(arguments);
  //bridge_dial2(arguments);
  var env = DotEnv(includePlatformEnvironment: true)..load();
  //recorderIp = env['HTTP_SERVER_ADDRESS']!;
  //recorderPort = int.parse(env['HTTP_SERVER_PORT']!);

  String voice_records = env['AGENTS_ENDPOINT']!;
  //String cdr_records = env['DASHBOARD_CDR_ENDPOINT']!;

  callQueue = CallQueue(Uri.parse(voice_records));
  call_center_bridge(arguments);
}
