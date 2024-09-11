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
import 'package:dart_ari_proxy/ari_apps/call_queue/http.dart';
import 'package:dart_ari_proxy/ari_apps/cc_bridge_agent_final.dart';
import 'package:dart_ari_proxy/globals.dart';
import 'package:dotenv/dotenv.dart';
import 'package:redis/redis.dart';

void main(List<String> arguments) async {
  //call_center_queue(arguments);
  //call_center(arguments);
  //app_ivr(arguments);
  //app_ivr_2(arguments);
  //bridge_dial(arguments);
  //bridge_dial2(arguments);
  var env = DotEnv(includePlatformEnvironment: true)..load();
  String apiIp = env['API_HTTP_SERVER_ADDRESS']!;
  int apiPort = int.parse(env['API_HTTP_SERVER_PORT']!);

  //String voice_records = env['AGENTS_ENDPOINT']!;
  //String cdr_records = env['DASHBOARD_CDR_ENDPOINT']!;

  String redisIp = env['REDIS_ADDRESS']!;
  int redisPort = int.parse(env['REDIS_PORT']!);
  String redisPassword = env['REDIS_PASSWORD']!;

  redisCmd = await redisConnection.connect(redisIp, redisPort);

  var redisRes = await redisCmd.send_object(["AUTH", redisPassword]);

  //redisPubsub = PubSub(cmd);

  print("Redis auth response: $redisRes");

  HttpAPIServer(apiIp, apiPort, redisIp, redisPort, redisPassword);

  String host = env['DB_HOST']!;
  String port = env['DB_PORT']!;
  String database = env['DB_DATABASE']!;
  String username = env['DB_USERNAME']!;
  String password = env['DB_PASSWORD']!;

  init_mysql_connection(host, port, database, username, password);
  CallQueue.fromDB().then((cq) {
    callQueue = cq;
  });
  call_center_bridge(arguments);
}
