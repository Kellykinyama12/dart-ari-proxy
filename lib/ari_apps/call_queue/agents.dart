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
  AgentState state = AgentState.UNKNOWN;
  AgentState status = AgentState.UNKNOWN;
  Statistics statistics = Statistics();

  Agent(this.endpoint);
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
