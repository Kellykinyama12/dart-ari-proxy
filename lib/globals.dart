import 'package:dart_ari_proxy/ari_apps/call_queue/call_queue.dart';
import 'package:eloquent/eloquent.dart';
import 'package:redis/redis.dart';

import 'ari_client/dashboard_client.dart';
import 'ari_http_proxy.dart';

WsServer? wsServer;

DasboardClient? dsbClient;

String api_key = 'asterisk:asterisk';

late CallQueue callQueue; // = CallQueue();

late String asteriskDbHost;
late String asteriskDbPort;
late String asteriskDbName;
late String asteriskDbUsername;
late String asteriskDbPassword;

// final manager = Manager();
final redisConnection = RedisConnection();

late PubSub redisPubsub; // = PubSub(command);
late Command redisCmd;

// void init_mysql_connection(String host, String port, String database,
//     String username, String password) {

// final manager = Manager();

//   manager.addConnection({
//     'driver': 'mysql',
//     'host': asteriskDbHost,
//     'port': asteriskDbPort,
//     'database': asteriskDbName,
//     'username': asteriskDbUsername,
//     'password': asteriskDbPassword,
//     // 'pool': true,
//     // 'poolsize': 2,
//   });

//   manager.setAsGlobal();
// }
