import 'package:dart_ari_proxy/ari_apps/call_queue/call_queue.dart';
import 'package:events_emitter/emitters/event_emitter.dart';
import 'package:redis/redis.dart';
import 'package:logging/logging.dart';

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

late String voiceLoggerIp;
late int voiceLoggerPort;

final events = EventEmitter();

Function(String)? currentAgent;

final Logger logger = Logger('MyAppLogger');
