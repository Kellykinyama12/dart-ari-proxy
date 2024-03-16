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

class Statistics {
  int receivedCalls = 0;
  int missedCalls = 0;
  int answereCalls = 0;
  int agentTerminatedCalls = 0;
  int callerTerminatedCalls = 0;
  int dialedCalls = 0;
}

class CallQueue {
  Map<String, Agent> agents = {};
}

class Agent {
  String? name; //?:string
  String? endpoint;
  String number; //:string
  String setNumber; //?:string
  AgentState state = AgentState.UNKNOWN;
  Statistics statistics = Statistics();

  Agent(this.number, this.setNumber);
}
