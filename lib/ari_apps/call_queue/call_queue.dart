import 'dart:convert';
import 'dart:io';

import 'package:dart_ari_proxy/ari_apps/call_queue/agents.dart';
import 'package:dart_ari_proxy/ari_client.dart';
import 'package:dart_ari_proxy/globals.dart';

HttpClient httpRtpClient = HttpClient();

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
    // agent_nums.forEach((numb) {
    //   agents[numb] = Agent(numb);
    // });

    // agentsAPI().then((resp) {
    //   var (resp, statusCode, err) = resp;
    // });
    agents.clear();

    if (uri != null) {
      print("Initialising agent data from api");
      agentsAPI(uri).then((value) {
        var (resp, statusCode, err) = value;
        // print(resp);

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
        var agentsList = jsonDecode(jsonData); //print(stringData);

        agentsList.forEach((agentEntry) {
          //print("Parsing JSON agent data: $agentEntry");
          agents[agentEntry["endpoint"]] = Agent.fromJSON(agentEntry);
          print("Create agent: ${agents[agentEntry["endpoint"]]}");
        });
        print("Agents available: ${agentsList.length}");
      }
    }
  }

  static Future<CallQueue> fromDB() async {
    final db = await manager.connection();

    //final dbdb) {
    var res = await db
        .table('agents')
//       .selectRaw('id,name,tel')
//       .join('contacts', 'contacts.id_client', '=', 'clients.id')
        .get();

    final resp = jsonEncode(res);
    db.disconnect();
    return CallQueue(jsonData: resp);

//   exit(0);
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
      //print("agent: $agent");
      if (agent.state == AgentState.LOGGEDIN &&
          agent.status == AgentState.IDLE) {
        bestAgent = agent;
      }

      // if (agent.state == AgentState.LOGGEDIN && agentsLogged.length < 10) {
      //   bestAgent = agent;
      // }

      if (bestAgent != null) {
        if (agent.state == AgentState.LOGGEDIN &&
            agent.status == AgentState.IDLE &&
            agent.statistics.answereCalls <
                bestAgent!.statistics.answereCalls) {
          bestAgent = agent;
        }
      }
    });

    return bestAgent;
  }
}

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
