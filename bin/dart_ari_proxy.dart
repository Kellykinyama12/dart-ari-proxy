import 'package:dart_ari_proxy/ari_apps/call_queue/call_queue.dart';
import 'package:dart_ari_proxy/ari_apps/call_queue/http.dart';
import 'package:dart_ari_proxy/ari_apps/cc_bridge_agent_final.dart';
import 'package:dart_ari_proxy/globals.dart';
import 'package:dotenv/dotenv.dart';

void main(List<String> arguments) async {
//Declare the variables
  var env = DotEnv(includePlatformEnvironment: true)..load();
  String apiIp = env['API_HTTP_SERVER_ADDRESS']!;
  int apiPort = int.parse(env['API_HTTP_SERVER_PORT']!);
  String redisIp = env['REDIS_ADDRESS']!;
  int redisPort = int.parse(env['REDIS_PORT']!);
  String redisPassword = env['REDIS_PASSWORD']!;

//initialise redis connection
  redisCmd = await redisConnection.connect(redisIp, redisPort);
  var redisRes = await redisCmd.send_object(["AUTH", redisPassword]);
  print("Redis auth response: $redisRes");

//initialise recorder API Server
  HttpAPIServer(apiIp, apiPort, redisIp, redisPort, redisPassword);

//initialise recorde daatabase values
  asteriskDbHost = env['AST_DB_HOST']!;
  asteriskDbPort = env['AST_DB_PORT']!;
  asteriskDbName = env['AST_DB_DATABASE']!;
  asteriskDbUsername = env['AST_DB_USERNAME']!;
  asteriskDbPassword = env['AST_DB_PASSWORD']!;

  String pbxHost = env['PBX_HOST']!;
  int pbxPort = int.parse(env['PBX_PORT']!);

//Get a list of agents from local DB
  callQueue = await CallQueue.fromDB();
  await callQueue.pbxAgentData(pbxHost, pbxPort);

  call_center_bridge(arguments);
}
