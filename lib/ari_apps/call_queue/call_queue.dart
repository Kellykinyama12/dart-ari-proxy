import 'package:dart_ari_proxy/ari_apps/call_queue/agents.dart';

class CallQueue {
  Map<String, Agent> agents = {};

  CallQueue(List<String> agent_nums) {
    agent_nums.forEach((numb) {
      agents[numb] = Agent(numb);
    });
  }

  Agent nextAgent() {
    Agent? bestAgent;
    agents.forEach((agent_num, agent) {});

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
  '1102'
];
