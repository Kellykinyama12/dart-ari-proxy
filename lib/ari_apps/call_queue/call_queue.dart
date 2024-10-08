import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:dart_ari_proxy/ari_apps/call_queue/agents.dart';
import 'package:dart_ari_proxy/ari_client.dart';
import 'package:dart_ari_proxy/ari_client/misc.dart';
import 'package:dart_ari_proxy/globals.dart';
import 'package:dotenv/dotenv.dart';
import 'package:eloquent/eloquent.dart';
import 'package:telnet/telnet.dart';
import 'package:eventify/eventify.dart';
import 'dart:math';

class AcdCall {
  String incomingChannel;

  Map<String, Agent> freeAgents = {};

  Agent? bestAgent;

  AcdCall(this.incomingChannel) {}
}

HttpClient httpRtpClient = HttpClient();

Timer? timer;
bool sentTbagCmd = false;
int receivedTbagDataCount = 0;
String strReceivedData = "";
bool receivedAgentsData = false;
bool sentAgentStatus = false;
bool receivedAgentStatus = false;

bool _hasLogin = false;

class CallCenterPerson {
  int? id;
  int? log_num;
  String? DirectroyNum;
  int? neqt;
  String? type;
  String? name;
  int? msg_num;
  int statusChecked = 0;
  String? agentState;
  String? agentStatus;
  String? abstract;

  String? statistics;
  String? status;
  String? lastDateCall;

  CallCenterPerson(
      {this.id,
      this.log_num,
      this.DirectroyNum,
      this.neqt,
      this.type,
      this.name,
      this.msg_num});

  @override
  String toString() {
    return "{ id: $id, log_num: $log_num, DirectroyNum: $DirectroyNum, neqt: $neqt, type: $type, name: $name, msg_num: $msg_num, statusChecked: $statusChecked, AgentStatus: $status}";
  }
}

Map<String, CallCenterPerson> callCenterPeople = {};

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
      print("text before login: $text");
      if (text.contains("last login:")) {
        print("Login successfull");
        _hasLogin = true;
      } else if (text.contains("login:")) {
        setTimeout(() {
          client!.write(TLTextMsg("$username\r\n"));
        }, 1000);
      } else if (text.contains("password:")) {
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
        int index = text.indexOf("directory number    :");
        if (index != -1) {
          int lastDateCallIndex = text.indexOf("last date call:");
          String lastDateCallText = text.substring(lastDateCallIndex);
          int delimiter = lastDateCallText.indexOf("|");
          lastDateCallText = lastDateCallText.substring(15, delimiter);

          //  print("Last date call: $lastDateCallText");

          String agentNum = text.substring(index);
          index = agentNum.indexOf("|");
          agentNum = agentNum.substring(21, index).trim();
          if (callCenterPeople[agentNum] != null) {
            callCenterPeople[agentNum]!.agentStatus = text;
          } else {
            callCenterPeople[agentNum] =
                CallCenterPerson(DirectroyNum: agentNum);
          }
          callCenterPeople[agentNum]!.lastDateCall = lastDateCallText;

          //   events.emit('message', text);
          events.emit('statusEvent', text);
        }
      }

      if (sentTbagCmd && !receivedAgentsData) {
        timer = setTimeout(() {
          receivedAgentsData = true;

          final entries = text.split("\r");

          entries.forEach((entry) {
            final fields = entry.split("|");

            //print("Agent list: $text");

            if (fields.length >= 8) {
              try {
                callCenterPeople[fields[3].trim()] = CallCenterPerson(
                    id: int.parse(fields[1]),
                    log_num: int.parse(fields[2]),
                    DirectroyNum: fields[3].trim(),
                    neqt: int.parse(fields[4]),
                    type: fields[5],
                    name: fields[6],
                    msg_num: int.parse(fields[7]));
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
            }, 200);
          });
        }, 10000);
      }

      if (!sentTbagCmd) {
        timer = setTimeout(() {
          client!.write(
              TLTextMsg("tabag\r\n")); //Command to get the list of agents
          sentTbagCmd = true;
          receivedTbagDataCount++;
        }, 2000);
      }
      currentAgent ??= (String agentNum) {
        strReceivedData = "";
        // timer = setTimeout(() {
        client!.write(TLTextMsg("agacd $agentNum\r\n"));
        sentTbagCmd = true;
        receivedTbagDataCount++;
        // }, 300);
      };
    }
  }
}

void _onError(TelnetClient? client, dynamic error) {
  print("[ERROR] $error");
}

void _onDone(TelnetClient? client) {
  _hasLogin = false;
  print("[DONE]");
}

Future<dynamic> agentsAPI(Uri uri) async {
  HttpClientRequest request = await httpRtpClient.getUrl(uri);
  HttpClientResponse response = await request.close();
  //print(response);
  final String stringData = await response.transform(utf8.decoder).join();

  return (stringData, response.statusCode, null);
}

class CallQueue {
  Map<String, Agent> agents = {};
  Map<String, Agent> agentsAnswered = {};
  Map<String, Agent> agentsLoggedIn = {};
  late Ari ari_client;

  Map<String, AcdCall> incomingAcdToAgents = {};

  Map<String, Agent> freeAgentsMap = {};

  CallQueue({Uri? uri, dynamic jsonData, dynamic calls}) {
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
      calls = jsonDecode(calls);
      print("Records runtime type: ${calls.runtimeType}");

      if (jsonData != null) {
        print("Initialising agent data from json");
        var agentsList = jsonDecode(jsonData);
        //loop through the list
        agentsList.forEach((agentEntry) {
          agents[agentEntry["endpoint"]] = Agent.fromJSON(agentEntry);

          calls.forEach((e) {
            if (e['agent_number']
                .contains(agents[agentEntry["endpoint"]]!.endpoint)) {
              print("record deaitl: ${e['agent_number']}");
              agents[agentEntry["endpoint"]]!.statistics.answereCalls++;
            }
            // e.forEach((k, v) {
            //   print("Entry: $v");
            // });
          });
          // print("Create agent: ${agents[agentEntry["endpoint"]]}");
        });
        print("Agents available: ${agentsList.length}");
      }
    }
  }

  static Future<CallQueue> fromDB() async {
    final manager = Manager();
    manager.addConnection({
      'driver': 'mysql',
      'host': asteriskDbHost,
      'port': asteriskDbPort,
      'database': asteriskDbName,
      'username': asteriskDbUsername,
      'password': asteriskDbPassword,
    });
    manager.setAsGlobal();
    final db = await manager.connection();
    var res = await db.table('agents').get();
    var calls = await db.table('recordings').get();
    var jsonCalls = jsonEncode(calls);
    final resp = jsonEncode(res);
    db.disconnect();
    return CallQueue(jsonData: resp, calls: jsonCalls);
  }

//   Agent getAgentWithLongestWaitingDuration() {
//   if (agents.isEmpty) {
//     throw ArgumentError('The agents list cannot be empty.');
//   }

//   Agent longestWaitingAgent = agents;
//   Duration longestDuration = DateTime.now().difference(longestWaitingAgent.waitingSince);

//   for (Agent agent in agents) {
//     Duration currentDuration = DateTime.now().difference(agent.waitingSince);
//     if (currentDuration > longestDuration) {
//       longestDuration = currentDuration;
//       longestWaitingAgent = agent;
//     }
//   }

//   return longestWaitingAgent;
// }

  List<CallCenterPerson> getFreeAgent() {
    // print("Getting free agents...");

    List<CallCenterPerson> freeAgents = [];
    callCenterPeople.forEach((k, v) {
      String status = processAgentStatusString(v);
      v.status = status;
      if (status == "free") {
        freeAgents.add(v);
        if (agents[v.DirectroyNum] != null) {
          freeAgentsMap[v.DirectroyNum!] = agents[v.DirectroyNum]!;
        }
      } else {
        freeAgentsMap.remove(v.DirectroyNum);
      }
    });
    return freeAgents;
  }

  String processAgentStateString(CallCenterPerson person) {
    String? text = person.agentStatus;
    String dynamicState = "";

    if (text == null) return "";

    int index = text.indexOf("directory number    :");
    if (index != -1) {
      //print("Emmiting agent status for: $text");
      String agentNum = text.substring(index);
      index = agentNum.indexOf("|");
      agentNum = agentNum.substring(21, index).trim();

      // Process agent static state
      int staticIndex = text.indexOf("static state  :");
      if (staticIndex == -1) return "";

      String staticText = text.substring(staticIndex);
      staticIndex = staticText.indexOf("|");
      String staticState = staticText.substring(15, staticIndex).trim();
      // agent.pbxState = staticState;
    }
    return dynamicState;
  }

  String processAgentStatusString(CallCenterPerson person) {
    String? text = person.agentStatus;
    String dynamicState = "";

    if (text == null) return "";

    int index = text.indexOf("directory number    :");
    if (index != -1) {
      //print("Emmiting agent status for: $text");
      String agentNum = text.substring(index);
      index = agentNum.indexOf("|");
      agentNum = agentNum.substring(21, index).trim();

      // Process agent static state
      int staticIndex = text.indexOf("static state  :");
      if (staticIndex == -1) return "";

      String staticText = text.substring(staticIndex);
      staticIndex = staticText.indexOf("|");
      String staticState = staticText.substring(15, staticIndex).trim();
      // agent.pbxState = staticState;

      if (staticState != "normal") {
        return "";
      }

      // Process agent dynamic state
      int dynamicIndex = text.indexOf("dynamic state :");
      if (dynamicIndex == -1) return "";

      String dynamicText = text.substring(dynamicIndex);
      dynamicIndex = dynamicText.indexOf("|");
      dynamicState = dynamicText.substring(15, dynamicIndex).trim();
      //agent.pbxStatus = dynamicState;

      if (dynamicState != "free") return "";

      // Process agent process group
      int pgIndex = text.indexOf("affect pg dir nb :");
      "affect pg dir nb :          8800";
      // if (pgIndex == -1) return;

      String pgText = text.substring(pgIndex);
      pgIndex = pgText.indexOf("|");
      String processGroup = pgText.substring(18, pgIndex).trim();
      //print("Processing group: $processGroup");

      if (processGroup != "8800") {
        agentsLoggedIn.remove(agentNum);
        return "";
      }
    }
    return dynamicState;
  }

  Agent? processAgentStatus(String text, String incomingChannel) {
    int index = text.indexOf("directory number    :");
    if (index != -1) {
      //print("Emmiting agent status for: $text");
      String agentNum = text.substring(index);
      index = agentNum.indexOf("|");
      agentNum = agentNum.substring(21, index).trim();
      if (callCenterPeople[agentNum] != null) {
        callCenterPeople[agentNum]!.agentStatus = text;
      } else {
        callCenterPeople[agentNum] = CallCenterPerson(DirectroyNum: agentNum);
      }

      // Process agent static state
      int staticIndex = text.indexOf("static state  :");
      if (staticIndex == -1) return null;

      String staticText = text.substring(staticIndex);
      staticIndex = staticText.indexOf("|");
      String staticState = staticText.substring(15, staticIndex).trim();
      // agent.pbxState = staticState;

      if (staticState != "normal") {
        agentsLoggedIn.remove(agentNum);
        return null;
      }

      // Process agent dynamic state
      int dynamicIndex = text.indexOf("dynamic state :");
      if (dynamicIndex == -1) return null;

      String dynamicText = text.substring(dynamicIndex);
      dynamicIndex = dynamicText.indexOf("|");
      String dynamicState = dynamicText.substring(15, dynamicIndex).trim();
      //agent.pbxStatus = dynamicState;

      if (dynamicState != "free") {
        freeAgentsMap.remove(agentNum);
        return null;
      }

      // Process agent process group
      int pgIndex = text.indexOf("affect pg dir nb :");
      "affect pg dir nb :          8800";
      // if (pgIndex == -1) return;

      String pgText = text.substring(pgIndex);
      pgIndex = pgText.indexOf("|");
      String processGroup = pgText.substring(18, pgIndex).trim();
      //print("Processing group: $processGroup");

      if (processGroup != "8800") {
        freeAgentsMap.remove(agentNum);
        agentsLoggedIn.remove(agentNum);
        return null;
      }
      if (agents[agentNum] != null) {
        agentsLoggedIn[agentNum] = agents[agentNum]!;
      }

      //bestAgent ??= agents[agentNum];
      //if (incomingToAgents[incomingChannel] == null) {
      if (agents[agentNum] != null) {
        //print(" agent status for: $agentNum, is : $dynamicState");
        incomingAcdToAgents[incomingChannel]!.freeAgents[agentNum] =
            agents[agentNum]!;

        freeAgentsMap[agentNum] = agents[agentNum]!;
        //incomingToAgents[incomingChannel] = agents[agentNum]!;
        // freeAgents[agentNum] = agents[agentNum]!;
      }
      // } else {
      //   if (agents[agentNum] != null) {
      //     Duration agent1currentDuration =
      //         DateTime.now().difference(agents[agentNum]!.waitingSince!);
      //     Duration agent2currentDuration = DateTime.now()
      //         .difference(incomingToAgents[incomingChannel]!.waitingSince!);

      //     //            if (currentDuration > longestDuration) {
      //     //   longestDuration = currentDuration;
      //     //   longestWaitingAgent = agent;
      //     // }

      //     print(" agent status for: $agentNum, is : $text");

      //     incomingToAgents[incomingChannel] = agents[agentNum]!;
      //   }
      // }
    }
  }

  Agent getAgentWithLongestWaitingDuration(List<Agent> agents) {
    if (agents.isEmpty) {
      throw ArgumentError('The agents list cannot be empty.');
    }

    Agent longestWaitingAgent = agents.first;

    // print(
    //     "last datec call for: ${longestWaitingAgent.endpoint} is ${callCenterPeople[longestWaitingAgent.endpoint]!.lastDateCall}");

    Duration longestDuration =
        DateTime.now().difference(longestWaitingAgent.waitingSince);

    for (Agent agent in agents) {
      Duration currentDuration = DateTime.now().difference(agent.waitingSince);
      if (currentDuration > longestDuration) {
        longestDuration = currentDuration;
        longestWaitingAgent = agent;
      }
    }

    return longestWaitingAgent;
  }

  void getLoggedInAgents() {
    if (!events.listeners.contains("statusEvent")) {
      events.on('statusEvent', (String data) {
        //print('String: $data');
        int index = data.indexOf("directory number    :");
        if (index != -1) {
          String agentNum = data.substring(index);
          index = agentNum.indexOf("|");
          agentNum = agentNum.substring(21, index).trim();

          callCenterPeople[agentNum]!.agentStatus = data;
          callCenterPeople[agentNum]!.status =
              processAgentStatusString(callCenterPeople[agentNum]!);
          if (callCenterPeople[agentNum]!.status != "free") {
            freeAgentsMap.remove(agentNum);
          }
        }
      });
    }
    //print("Getting logged in agent list");
    if (currentAgent != null) {
      agents.forEach((agent_num, agent) {
        if (agentsLoggedIn[agent_num] == null) {
          setTimeout(() {
            currentAgent!(agent_num);
          }, 100);
        }
      });
    }

    callCenterPeople.forEach((agent_num, agent) {
      if (agent.agentStatus == null) return;
      String text = agent.agentStatus!;
      int index = text.indexOf("directory number    :");
      if (index != -1) {
        String agentNum = text.substring(index);
        index = agentNum.indexOf("|");
        agentNum = agentNum.substring(21, index).trim();
        callCenterPeople[agentNum]!.agentStatus = text;
        //print("Emmiting agent status for: $agentNum");

        // Process agent static state
        int staticIndex = text.indexOf("static state  :");
        if (staticIndex == -1) return null;

        String staticText = text.substring(staticIndex);
        staticIndex = staticText.indexOf("|");
        String staticState = staticText.substring(15, staticIndex).trim();
        // agent.pbxState = staticState;

        if (staticState != "normal") {
          return;
        }

        // Process agent process group
        int pgIndex = text.indexOf("affect pg dir nb :");
        // if (pgIndex == -1) return;

        String pgText = text.substring(pgIndex);
        pgIndex = pgText.indexOf("|");
        String processGroup = pgText.substring(18, pgIndex).trim();
        //print("Processing group: $processGroup");

        if (processGroup != "8800") {
          return;
        }
        if (agents[agentNum] != null) {
          agentsLoggedIn[agentNum] = agents[agentNum]!;
        }
      }
    });
  }

  Future<Agent> nextAgentV2(String incomingChannel) async {
    incomingAcdToAgents[incomingChannel] = AcdCall(incomingChannel);

    // Ensure the event listener is added only once
    if (!events.listeners.contains('statusEvent')) {
      events.on('statusEvent', (String data) async {
        processAgentStatus(data, incomingChannel);
      });
    }

    List<String> priorityKeys = freeAgentsMap.keys.toList();
    //List<String> keys = callQueue.agents.keys.toList();
    List<String> answereKeys = callQueue.agentsAnswered.keys.toList();
    List<String> loggedInKeys = agentsLoggedIn.keys.toList();

    priorityKeys.shuffle(Random());
    answereKeys.shuffle(Random());
    loggedInKeys.shuffle(Random());

// Create a LinkedHashSet to maintain the order and remove duplicates

    Set<String> combinedSet = LinkedHashSet<String>()
      ..addAll(priorityKeys)
      ..addAll(loggedInKeys)
      ..addAll(answereKeys);

    List<String> combinedList = combinedSet.toList();

    print("Agent list: $loggedInKeys");

    return await getBestAgent(combinedList, combinedList[0], incomingChannel);
  }

  Future<Agent> getBestAgent(
      List<String> keys, String currentKey, String incomingChannel) async {
    final completer = Completer<Agent>();
    print("Getting best agent $currentKey");
    int currentIndex = keys.indexOf(currentKey);

    if (currentIndex == -1) {
      throw ArgumentError('The provided key does not exist in the map.');
    }

    int nextIndex = (currentIndex + 1) % keys.length;

    String nextKey = keys[nextIndex];

    // Agent currAgent = agents[nextKey]!;
    Agent currAgent = agents[nextKey]!;

    if (incomingAcdToAgents[incomingChannel] != null &&
        incomingAcdToAgents[incomingChannel]!.freeAgents.isEmpty) {
      if (currentAgent != null) {
        currentAgent!(currAgent.endpoint);
      } else {
        throw "CurrentAgent function cannot be null";
      }
      await Future.delayed(Duration(milliseconds: 1000));

      return getBestAgent(keys, nextKey, incomingChannel);
    } else {
      List<Agent> keyValueList = [];
      incomingAcdToAgents[incomingChannel]!.freeAgents.forEach((key, value) {
        keyValueList.add(value);
      });

      print("Free agents for $incomingChannel is ${keyValueList}");

      // .forEach((k, v) => keyValueList.add(v));
      incomingAcdToAgents[incomingChannel]!.bestAgent =
          getAgentWithLongestWaitingDuration(keyValueList);
      Agent bestAgent = incomingAcdToAgents[incomingChannel]!.bestAgent!;
      completer.complete(bestAgent);
    }
    return completer.future;
  }

  Future<bool> waitForLoggedInAgent() async {
    // print("Getting looged in agents...");
    final completer = Completer<bool>();
    getLoggedInAgents();

    if (agentsLoggedIn.isEmpty || agentsLoggedIn.length < 30) {
      await Future.delayed(Duration(milliseconds: 1000));

      //  print("Logged in list: ${agentsLoggedIn.keys.toList()}");
      print("Logged in list: ${agentsLoggedIn.keys.toList().length}");
      print("Realtime free agents : ${freeAgentsMap.keys.toList()}");
      print("Realtime count : ${freeAgentsMap.keys.toList().length}");
      print("Free agents before: ${getFreeAgent().length}");

      return waitForLoggedInAgent();
    } else {
      print("Logged in agents: ${agentsLoggedIn.keys.toList()}");
      completer.complete(true);
    }

    return false;
  }

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

  Future<bool> pbxAgentData(String pbxHost, int pbxPort) async {
    var env = DotEnv(includePlatformEnvironment: true)..load();
    //declare and initialise pbx settings
    String host = env['PBX_CREDS_HOST']!;
    int port = int.parse(env['PBX_CREDS_PORT']!);
    String path = env['PBX_CREDS_PATH']!;
    String apiKey = env['PBX_CREDS_API_KEY']!;

    ITelnetClient? client;

    late ITLConnectionTask task;
    //await pbxCreds(host, port, path, apiKey);

//login into the pbx
    if (username != null) {
      task = TelnetClient.startConnect(
        host: pbxHost,
        port: pbxPort,
        onEvent: _onEvent,
        onError: _onError,
        onDone: _onDone,
      );

      // Wait the connection task finished.
      await task.waitDone();

      // / Get the `TelnetClient` instance. It will be `null` if connect failed.
      client = task.client;
      if (client == null) {
        throw ("Fail to connect to $pbxHost:$pbxPort");
      } else {
        print("Successfully connect to $pbxHost:$pbxPort");
      }
    } else {
      throw "PBX credentials cannot be null. make sure they are available";
    }

    setTimeout(() {
      if (!_hasLogin) {
        throw "PBX connection failed";
      }
    }, 7000);

    // final completer = Completer<bool>();

    // if (!_hasLogin) {
    //   await Future.delayed(Duration(milliseconds: 30000));

    //   await client.terminate();

    //   return pbxAgentData(pbxHost, pbxPort);
    // } else {
    //   completer.complete(true);
    // }
    return false;
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
