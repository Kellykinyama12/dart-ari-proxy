import 'package:dart_ari_proxy/ari_apps/call_queue/agents.dart';
import 'package:dart_ari_proxy/ari_client.dart';

class CallQueue {
  Map<String, Agent> agents = {};
  late Ari ari_client;

  CallQueue(List<String> agent_nums) {
    agent_nums.forEach((numb) {
      agents[numb] = Agent(numb);
    });
  }

  Agent? nextAgent() {
    Agent? bestAgent;
    agents.forEach((agent_num, agent) {
      if (bestAgent == null) {
        bestAgent = agent;
        //return;
      }
      // else if (bestAgent!.state == AgentState.LOGGEDIN) {
      //   if (agent.state == AgentState.UNKNOWN) {
      //     if (agent.statistics.unknownStateCallsTried <=
      //         //bestAgent!.statistics.unknownStateCallsTried
      //         3) {
      //       bestAgent = agent;
      //     }
      //     //bestAgent = agent;
      //   } else if (agent.state == AgentState.LOGGEDIN &&
      //       agent.statistics.answereCalls <=
      //           bestAgent!.statistics.answereCalls) {
      //     bestAgent = agent;
      //   }
      // } else if (bestAgent!.state == AgentState.UNKNOWN) {
      //   if (agent.state == AgentState.UNKNOWN) {
      //     if (agent.statistics.unknownStateCallsTried <=
      //         bestAgent!.statistics.unknownStateCallsTried) {
      //       bestAgent = agent;
      //     }
      //     //bestAgent = agent;
      //   }

      //   //return;
      // }
      else {
        //Best agent is logged in
        if (bestAgent!.state == AgentState.LOGGEDIN &&
            agent.state == AgentState.UNKNOWN &&
            agent.statistics.unknownStateCallsTried < 3 &&
            agent.status != AgentState.ONCONVERSATION) {
          print("Selecting alernative agent: ${agent.endpoint}");
          bestAgent = agent;
        } else if (bestAgent!.state == AgentState.LOGGEDIN &&
            agent.state == AgentState.LOGGEDIN &&
            agent.statistics.answereCalls <
                bestAgent!.statistics.answereCalls &&
            agent.status != AgentState.ONCONVERSATION) {
          bestAgent = agent;
        } else if (bestAgent!.state == AgentState.UNKNOWN &&
            agent.state == AgentState.UNKNOWN &&
            agent.statistics.unknownStateCallsTried <
                bestAgent!.statistics.unknownStateCallsTried &&
            agent.status != AgentState.ONCONVERSATION) {
          bestAgent = agent;
        } else if (bestAgent!.state == AgentState.LOGGEDIN &&
            agent.state == AgentState.LOGGEDIN &&
            agent.statistics.receivedCalls <
                bestAgent!.statistics.receivedCalls &&
            agent.status != AgentState.ONCONVERSATION) {
          bestAgent = agent;
        }
      }
    });

    return bestAgent!;
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
  '8969',
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
