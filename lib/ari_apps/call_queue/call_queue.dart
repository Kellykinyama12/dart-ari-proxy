import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_ari_proxy/ari_apps/call_queue/agents.dart';
import 'package:dart_ari_proxy/ari_client.dart';
import 'package:dart_ari_proxy/ari_client/misc.dart';
import 'package:dart_ari_proxy/globals.dart';
import 'package:dotenv/dotenv.dart';
import 'package:eloquent/eloquent.dart';
import 'package:telnet/telnet.dart';

HttpClient httpRtpClient = HttpClient();

// String host = "10.1.8.222";
// int port = 23;

Timer? timer;
bool sentTbagCmd = false;
int receivedTbagDataCount = 0;
String strReceivedData = "";
bool receivedAgentsData = false;
bool sentAgentStatus = false;
bool receivedAgentStatus = false;

class CallCenterPerson {
  int id;
  int log_num;
  String DirectroyNum;
  int neqt;
  String type;
  String name;
  int msg_num;
  int statusChecked = 0;
  String? AgentStatus;

  String? statistics;

  CallCenterPerson(this.id, this.log_num, this.DirectroyNum, this.neqt,
      this.type, this.name, this.msg_num);

  @override
  String toString() {
    return "{ id: $id, log_num: $log_num, DirectroyNum: $DirectroyNum, neqt: $neqt, type: $type, name: $name, msg_num: $msg_num, statusChecked: $statusChecked, AgentStatus: $AgentStatus}";
  }
}

Map<String, CallCenterPerson> callCenterPeople = {};

Future<dynamic> pbxCreds(
    String host, int port, String path, String apiKey) async {
  // baseUrl.path = baseUrl.path + '/channels';

  HttpClient client = HttpClient();
  var uri = Uri(
      scheme: "http",
      userInfo: "",
      host: host,
      port: port,
      path: path,
      query: "",
      queryParameters: {'api_key': api_key}
      //String? fragment
      );
  //var uri = Uri.http(baseUrl);
  try {
    HttpClientRequest request = await client.getUrl(uri);
    request.headers.add(HttpHeaders.authorizationHeader, 'Bearer $apiKey');

    //request.headers.set(name, value);
    HttpClientResponse response = await request.close();
    //print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    //print(response.statusCode);
    //print(stringData);
    final creds = jsonDecode(stringData);
    username = creds["username"];
    password = creds["password"];
    return (statusCode: response.statusCode, resp: stringData);
  } catch (e) {
    print("error: $e");
  }
}

var _hasLogin = false;

String? username;
String? password;

const echoEnabled = true;
final _willReplyMap = <TLOpt, List<TLMsg>>{
  TLOpt.echo: [
    echoEnabled
        ? TLOptMsg(TLCmd.doIt, TLOpt.echo) // [IAC DO ECHO]
        : TLOptMsg(TLCmd.doNot, TLOpt.echo)
  ], // [IAC DON'T ECHO]
  TLOpt.suppress: [
    TLOptMsg(TLCmd.doIt, TLOpt.suppress)
  ], // [IAC DO SUPPRESS_GO_AHEAD]
  TLOpt.logout: [],
};
final _doReplyMap = <TLOpt, List<TLMsg>>{
  TLOpt.echo: [
    echoEnabled
        ? TLOptMsg(TLCmd.will, TLOpt.echo) // [IAC WILL ECHO]
        : TLOptMsg(TLCmd.wont, TLOpt.echo)
  ], // [IAC WONT ECHO]
  TLOpt.logout: [],
  TLOpt.tmlType: [
    TLOptMsg(TLCmd.will, TLOpt.tmlType), // [IAC WILL TERMINAL_TYPE]
    TLSubMsg(TLOpt.tmlType, [
      0x00,
      0x41,
      0x4E,
      0x53,
      0x49
    ]), // [IAC SB TERMINAL_TYPE IS ANSI IAC SE]
  ],
  TLOpt.windowSize: [
    TLOptMsg(TLCmd.will, TLOpt.windowSize), // [IAC WILL WINDOW_SIZE]
    TLSubMsg(TLOpt.windowSize,
        [0x00, 0x5A, 0x00, 0x18]), // [IAC SB WINDOW_SIZE 90 24 IAC SE]
  ],
};

void _onEvent(TelnetClient? client, TLMsgEvent event) {
  if (event.type == TLMsgEventType.write) {
    //print("[WRITE] ${event.msg}");
  } else if (event.type == TLMsgEventType.read) {
    //Print raw data
    //print("[READ] ${event.msg}");

    if (event.msg is TLOptMsg) {
      final cmd = (event.msg as TLOptMsg).cmd; // Telnet Negotiation Command.
      final opt = (event.msg as TLOptMsg).opt; // Telnet Negotiation Option.

      if (cmd == TLCmd.wont) {
        // Write [IAC DO opt].
        //print("Writing [IAC DO opt]");
        client?.write(TLOptMsg(TLCmd.doNot, opt));
      } else if (cmd == TLCmd.doNot) {
        // Write [IAC WON'T opt].
        //print("Writing [IAC WON'T opt]");
        client?.write(TLOptMsg(TLCmd.wont, opt));
      } else if (cmd == TLCmd.will) {
        if (_willReplyMap.containsKey(opt)) {
          // Reply the option.
          for (var msg in _willReplyMap[opt]!) {
            //print("Writing msg: $msg");
            client?.write(msg);
          }
        } else {
          // Write [IAC DON'T opt].
          //print("Writing [IAC DON'T opt]");
          client?.write(TLOptMsg(TLCmd.doNot, opt));
        }
      } else if (cmd == TLCmd.doIt) {
        // Reply the option.
        if (_doReplyMap.containsKey(opt)) {
          for (var msg in _doReplyMap[opt]!) {
            //print("Replying the option: $msg");
            client?.write(msg);
          }
        } else {
          // Write [IAC WON'T opt].
          //print("Writing [IAC WON'T opt]");
          client?.write(TLOptMsg(TLCmd.wont, opt));
        }
      }
    } else if (!_hasLogin && event.msg is TLTextMsg) {
      final text = (event.msg as TLTextMsg).text.toLowerCase();
      // if (text.contains("welcome")) {
      //   _hasLogin = true;
      //   print("[INFO] Login OK!");
      print("text before login: $text");
      if (text.contains("last login:")) {
        //   // Write [password].
        print("Login successfull");
        _hasLogin = true;
        //state = TELNET_STATE.LOGGED_IN;
        //client!.write(TLTextMsg("mgr\r\n"));
      } else if (text.contains("login:")) {
        //   // Write [username].
        //print("Writing username: $username");
        setTimeout(() {
          client!.write(TLTextMsg("$username\r\n"));
        }, 1000);
      } else if (text.contains("password:")) {
        //   // Write [password].
        //print("Writing username: $password");
        setTimeout(() {
          client!.write(TLTextMsg("$password\r\n"));
        }, 1000);
      }
      //print(text);
    }
    if (_hasLogin && event.msg is TLTextMsg) {
      final text = (event.msg as TLTextMsg).text.toLowerCase();
      strReceivedData = strReceivedData + text;
      receivedTbagDataCount++;

      if (sentAgentStatus) {
        //print("Agent status: $text");
        int index = text.indexOf("directory number    :");
        if (index != -1) {
          String agentNum = text.substring(index);
          index = agentNum.indexOf("|");
          agentNum = agentNum.substring(21, index);
          //print("Agent num: $agentNum");
          callCenterPeople[agentNum.trim()]?.AgentStatus = text;
        }
      }

      //if (sentTbagCmd) print("Received times: $receivedTbagDataCount");
      if (sentTbagCmd && !receivedAgentsData) {
        timer = setTimeout(() {
          receivedAgentsData = true;

          //print("Receive agent data: $strReceivedData");

          final entries = text.split("\r");
          //print("Receive agent data: $entries");

          entries.forEach((entry) {
            final fields = entry.split("|");
            if (fields.length >= 8) {
              try {
                callCenterPeople[fields[3].trim()] = CallCenterPerson(
                    int.parse(fields[1]),
                    int.parse(fields[2]),
                    fields[3].trim(),
                    int.parse(fields[4]),
                    fields[5],
                    fields[6],
                    int.parse(fields[7]));
                // print("Error: $callCenterPeople");
              } catch (e) {
                print("Error: $e");
              }
            }
          });

          callCenterPeople.forEach((key, person) {
            setTimeout(() {
              client!.write(TLTextMsg("agacd ${person.DirectroyNum}\r\n"));
              sentAgentStatus = true;
            }, 5000);
          });
        }, 10000);
      }

      if (!sentTbagCmd) {
        timer = setTimeout(() {
          client!.write(TLTextMsg("tabag\r\n"));
          sentTbagCmd = true;
          receivedTbagDataCount++;
        }, 5000);
      }
      currentAgent ??= (String agentNum) {
        //client!.write(TLTextMsg("$agentNum\r\n"));
        strReceivedData = "";
        timer = setTimeout(() {
          client!.write(TLTextMsg("agacd $agentNum\r\n"));
          sentTbagCmd = true;
          receivedTbagDataCount++;
        }, 1000);
      };

      // const oneSec = Duration(seconds: 4);
      // Timer.periodic(oneSec, (Timer t) {
      //   strReceivedData = "";
      //   t.cancel();
      //   if (currentAgent != null) {
      //     client!.write(TLTextMsg("agacd $currentAgent\r\n"));
      //   }
      // });
    }
  }
}

void _onError(TelnetClient? client, dynamic error) {
  print("[ERROR] $error");
}

void _onDone(TelnetClient? client) {
  print("[DONE]");
}

Future<dynamic> agentsAPI(Uri uri) async {
  // baseUrl.path = baseUrl.path + '/channels';

  //10.100.54.137
  // var uri = Uri(
  //   scheme: "http",
  //   userInfo: "",
  //   // host: "zqa1.zesco.co.zm",
  //   host: "localhost",
  //   //port: 8080,
  //   port: 8000,
  //   path: "/api/agents",
  //   //Iterable<String>? pathSegments,
  //   //query: "",
  //   //queryParameters: {'filename': filename}
  //   //String? fragment
  // );

//HttpClientRequest request = await client.getUrl(uri);
  //var uri = Uri.http(baseUrl, '/channels/${channelId}/answer', qParams);
  HttpClientRequest request = await httpRtpClient.getUrl(uri);
  HttpClientResponse response = await request.close();
  //print(response);
  final String stringData = await response.transform(utf8.decoder).join();
  //print(stringData);
  //print(response.statusCode);
  // var port = jsonDecode(stringData); //print(stringData);

  // return port['rtp_port'];
  return (stringData, response.statusCode, null);
}

class CallQueue {
  Map<String, Agent> agents = {};
  Map<String, Agent> agentsLogged = {};
  late Ari ari_client;

  CallQueue({Uri? uri, dynamic jsonData}) {
    agents.clear();

    if (uri != null) {
      print("Initialising agent data from api");
      agentsAPI(uri).then((value) {
        var (resp, statusCode, err) = value;
        var agentsList = jsonDecode(resp); //print(stringData);
        print("Agents available: ${agentsList.length}");
        agentsList.forEach((agentEntry) {
          //print("Parsing JSON agent data: $agentEntry");
          agents[agentEntry["endpoint"]] = Agent.fromJSON(agentEntry);
          print("Create agent: ${agents[agentEntry["endpoint"]]}");
        });
      });
    } else {
      if (jsonData != null) {
        print("Initialising agent data from json");
        var agentsList = jsonDecode(jsonData);
        //loop through the list
        agentsList.forEach((agentEntry) {
          agents[agentEntry["endpoint"]] = Agent.fromJSON(agentEntry);
          print("Create agent: ${agents[agentEntry["endpoint"]]}");
        });
        print("Agents available: ${agentsList.length}");
      }
    }
  }

  static Future<CallQueue> fromDB() async {
    final manager = Manager();
//connect to the local db
    manager.addConnection({
      'driver': 'mysql',
      'host': asteriskDbHost,
      'port': asteriskDbPort,
      'database': asteriskDbName,
      'username': asteriskDbUsername,
      'password': asteriskDbPassword,
      // 'pool': true,
      // 'poolsize': 2,
    });
    manager.setAsGlobal();
    final db = await manager.connection();
    var res = await db
        .table('agents')
//       .selectRaw('id,name,tel')
//       .join('contacts', 'contacts.id_client', '=', 'clients.id')
        .get();
    final resp = jsonEncode(res);
    db.disconnect();
    return CallQueue(jsonData: resp);
  }

  // factory CallQueue.fromList(List<String> agent_nums) {
  //   Map<String, Agent> agents = {};
  //   agent_nums.forEach((numb) {
  //     agents[numb] = Agent(numb);
  //   });

  //   return CallQueue(agent_numbs: agents);
  // }

  fromAgentsAPI() {}

  Agent? nextAgent() {
    Agent? bestAgent;
    agents.forEach((agent_num, agent) {
      // final manager = Manager();
      // manager.addConnection({
      //   'driver': 'mysql',
      //   'host': '10.44.0.55',
      //   'port': '3306',
      //   'database': 'asterisk',
      //   'username': 'dashboard',
      //   'password': 'dashboard.123',
      //   // 'pool': true,
      //   // 'poolsize': 2,
      // });

      // manager.setAsGlobal();
      // final db = await manager.connection();
      if (callCenterPeople[agent_num] != null) {
        // print("pbx agent status: ${callCenterPeople[agent_num]?.AgentStatus}");

        if (callCenterPeople[agent_num]!.AgentStatus != null) {
          // print("Agent status: ${callCenterPeople[agent_num]!.AgentStatus}");
          String staticText = callCenterPeople[agent_num]!.AgentStatus!;
          String dyanmicText = callCenterPeople[agent_num]!.AgentStatus!;
          String pg = callCenterPeople[agent_num]!.AgentStatus!;
          int staticIndex = staticText.indexOf("static state  :");

          if (staticIndex != -1) {
            String agentStatus = staticText.substring(staticIndex);
            staticIndex = agentStatus.indexOf("|");
            agentStatus = agentStatus.substring(15, staticIndex);
            //print("Agent status: $agentNum");
            agent.pbxStatus = agentStatus;

            if (agent.pbxStatus!.trim() == "normal") {
              //print("Agent status: ${agent.pbxStatus}");
              // print(
              //     "Agent state normal: ${callCenterPeople[agent_num]!.AgentStatus}");
              agent.state = AgentState.LOGGEDIN;
              agent.status = AgentState.IDLE;

              int dynamicIndex = dyanmicText.indexOf("dynamic state :");

              if (dynamicIndex != -1) {
                String agentDynamicStatus = dyanmicText.substring(dynamicIndex);
                dynamicIndex = agentDynamicStatus.indexOf("|");
                agentStatus = agentDynamicStatus.substring(15, dynamicIndex);
                //print("Agent dynamic status: ${agentDynamicStatus}");
                agent.pbxStatus = agentDynamicStatus;

                if (agentStatus.trim() == "free") {
                  // print("Agent status: ${agent.pbxStatus}");
                  "prefer pg dir nb :          8800";
                  int pgIndex = pg.indexOf("prefer pg dir nb :");
                  if (pgIndex != -1) {
                    String pgSubString = pg.substring(pgIndex);
                    pgIndex = pgSubString.indexOf("|");
                    pgSubString = pgSubString.substring(18, pgIndex);
                    print("Processing group: $pgSubString");

                    if (pgSubString.trim() == "8800") {
//                       var res = await db
//                           .table('recordings')
//                           .where('dst', '=', agent.endpoint)
// //       .selectRaw('id,name,tel')
// //       .join('contacts', 'contacts.id_client', '=', 'clients.id')
//                           .get();
//                       final resp = jsonEncode(res);
//                       //print("Calls: ${resp}");
//                       agent.statistics.answereCalls = resp.length;

                      agent.state = AgentState.LOGGEDIN;
                      agent.status = AgentState.IDLE;
                      if (bestAgent == null)
                        bestAgent = agent;
                      else {
                        if (bestAgent!.statistics.answereCalls >=
                            agent.statistics.answereCalls) {
                          bestAgent = agent;
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }

        "dynamic state :     ext acd conv |";
      }

      //await db.disconnect();
      //print("agent: $agent");
    });
    if (currentAgent != null && bestAgent != null) {
      currentAgent!(bestAgent!.endpoint);
    }

    return bestAgent;
  }

  Future<void> pbxAgentData(String pbxHost, int pbxPort) async {
    var env = DotEnv(includePlatformEnvironment: true)..load();
    //declare and initialise pbx settings
    String host = env['PBX_CREDS_HOST']!;
    int port = int.parse(env['PBX_CREDS_PORT']!);
    String path = env['PBX_CREDS_PATH']!;
    String apiKey = env['PBX_CREDS_API_KEY']!;
    await pbxCreds(host, port, path, apiKey);

//login into the pbx
    if (username != null) {
      final task = TelnetClient.startConnect(
        host: pbxHost,
        port: pbxPort,
        onEvent: _onEvent,
        onError: _onError,
        onDone: _onDone,
      );

      // Wait the connection task finished.
      await task.waitDone();

      // / Get the `TelnetClient` instance. It will be `null` if connect failed.
      final client = task.client;
      if (client == null) {
        throw ("Fail to connect to $pbxHost:$pbxPort");
      } else {
        print("Successfully connect to $pbxHost:$pbxPort");
      }
    } else {
      throw "PBX credentials cannot be null. make sure they are available";
    }
  }
}

//list used for the test
List<String> agent_nums = [
  '8966',
  '1096',
  '1013',
  '8932',
  '1059',
  '1091',
  '1066',
  '8983',
  '1011',
  '8993',
  '8807',
  '8977',
  '1094',
  '8929',
  '8988',
  '8948',
  '8956',
  '1097',
  '8920',
  '8804',
  '8830',
  '8814',
  '8913',
  '8984',
  '1102',
  '1027',
  '8916',
  '1004',
  '8920',
  '8806',
  '8976',
  '8979',
  '1049',
  '8943',
  '1083',
  '1001',
  '8949',
  '1075',
  '8917',
  '8916',
  '8922',
  '8930',
  '1032',
  '8821',
  '8715',
  '8700',
  '8701',
  '8725',
  '1061',
  '8980',
  '8923',
  '8952',
  '1029',
  '1063',
  '1019',
  '8963',
  '1035',
  '8815',
  '1072',
  '1076',
  '8717',
  '8841',
  '8970',
  //'8969',
  '8833',
  '8727',
  '8704',
  '8936',
  '8832',
  '8824',
  '8710',
  '8974',
  '8716',
  '1031',
  '8836',
  '1060',
  '1034',
  '1003'
];
