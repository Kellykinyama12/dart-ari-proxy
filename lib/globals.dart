import 'package:dart_ari_proxy/ari_apps/call_queue/call_queue.dart';

import 'ari_client/dashboard_client.dart';
import 'ari_http_proxy.dart';

WsServer? wsServer;

DasboardClient? dsbClient;

String api_key = 'asterisk:asterisk';

late CallQueue callQueue;// = CallQueue();
