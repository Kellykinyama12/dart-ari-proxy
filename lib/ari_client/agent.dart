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
  Agent(String agentName,
      {required String agentNumber, String? agentSetNumber, AgentState? state})
      : agentName = agentName,
        agentNumber = agentNumber,
        agentSetNumber = agentSetNumber {}
  String? agentName; //?:string
  String agentNumber; //:string
  String? agentSetNumber; //?:string
  AgentState state = AgentState.UNKNOWN;
  num? callsServed; //:number;
  //loggedIn:boolean;
}
