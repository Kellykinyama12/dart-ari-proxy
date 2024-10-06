import 'dart:convert';

import 'package:dart_ari_proxy/globals.dart';
import 'package:eloquent/eloquent.dart';

enum AgentState {
  LOGGEDIN,
  LOGGEDOUT,
  ONWITHDRAW,
  ONCONVERSATION,
  IDLE,
  WRAPPINGUP,
  ONPRIVATECALL,
  RINGING,
  UNKNOWN
}

class Agent {
  String? name; //?:string
  String endpoint;
  String? number; //:string
  String? setNumber; //?:string
  AgentState? state; // = AgentState.UNKNOWN;
  AgentState? status; // = AgentState.UNKNOWN;
  Statistics statistics = Statistics();
  String? pbxState;
  String? pbxStatus;
  bool databaseRefresh = true;
  DateTime waitingSince = DateTime.now();

  Agent(this.endpoint,
      {this.name, this.state, this.status, this.number, this.setNumber}) {}

  static Future<Agent> refreshDataFromDB(String endpoint) async {
    final manager = Manager();

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

    //final dbdb) {
    var res = await db
        .table('recordings')
        .where('agent_number', '=', endpoint)
//       .selectRaw('id,name,tel')
//       .join('contacts', 'contacts.id_client', '=', 'clients.id')
        .get();

    final resp = jsonEncode(res);
    print("agent stats: $resp");
    db.disconnect();
    return Agent(endpoint); //,
    //{this.name, this.state, this.status, this.number, this.setNumber})
  }

  void saveStatusToDb(String status) async {
    var manager = Manager();
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

    final db = await manager.connection();

    await db
        .table('agents')
        .where('endpoint', '=', endpoint)
        .update({'state': status});

    await db.disconnect();
  }

  factory Agent.fromJSON(data) {
    AgentState state = AgentState.UNKNOWN;
    AgentState status = AgentState.UNKNOWN;

    switch (data["state"]) {
      case "LOGGED_OUT":
        {
          state = AgentState.LOGGEDOUT;
        }
      case "LOGGED_IN":
        {
          state = AgentState.LOGGEDIN;
        }
      default:
        {
          status = AgentState.UNKNOWN;
        }
    }

    switch (data["status"]) {
      case "WITHDRAWN":
        {
          status = AgentState.ONWITHDRAW;
        }
      case "ASSIGNED":
        {
          status = AgentState.LOGGEDIN;
        }

      case "IDLE":
        {
          status = AgentState.IDLE;
        }

      default:
        {
          status = AgentState.UNKNOWN;
        }
    }

    return Agent(data["endpoint"],
        name: data["name"], state: state, status: status);
  }

  @override
  String toString() {
    // TODO: implement ==
    return "{agent_endpoint: $endpoint, state: $state, status: $status}";
  }
}

class Statistics {
  int receivedCalls = 0;
  int missedCalls = 0;
  int answereCalls = 0;
  int agentTerminatedCalls = 0;
  int callerTerminatedCalls = 0;
  int dialedCalls = 0;
  int unknownStateCallsTried = 0;
}
