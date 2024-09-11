import 'package:dart_ari_proxy/ari_apps/call_queue/call_queue.dart';
import 'package:eloquent/eloquent.dart';
import 'package:redis/redis.dart';

import 'ari_client/dashboard_client.dart';
import 'ari_http_proxy.dart';

WsServer? wsServer;

DasboardClient? dsbClient;

String api_key = 'asterisk:asterisk';

late CallQueue callQueue; // = CallQueue();

final manager = Manager();
final redisConnection = RedisConnection();

late PubSub redisPubsub;// = PubSub(command);
 late Command redisCmd;

void init_mysql_connection(String host, String port, String database,
    String username, String password) {
  manager.addConnection({
    'driver': 'mysql',
    'host': host,
    'port': port,
    'database': database,
    'username': username,
    'password': password,
    // 'pool': true,
    // 'poolsize': 2,
  });

  manager.setAsGlobal();
}
