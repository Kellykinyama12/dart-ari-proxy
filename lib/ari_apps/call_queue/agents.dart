enum AgentState {
  LOGGEDIN,
  LOGGEDOUT,
  ONWITHDRAW,
  ONCONVERSATION,
  IDLE,
  WRAPPINGUP,
  ONPRIVATECALL,
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

  Agent(this.endpoint,
      {this.name, this.state, this.status, this.number, this.setNumber});

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
      case "LOGGED_IN":
        {
          status = AgentState.LOGGEDIN;
        }

      default:
        {
          status = AgentState.UNKNOWN;
        }
    }

    return Agent(data["endpoint"],
        name: data["name"], state: state, status: status);
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
