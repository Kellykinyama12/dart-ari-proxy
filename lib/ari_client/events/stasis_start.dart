import 'package:dart_ari_proxy/ari_client/Events/event.dart';

import '../ChannelsApi.dart';

class StasisStart extends Event {
  StasisStart(this.args, this.channel, this.json) : super("StasisStart") {}
  /**
     * Arguments to the application.
     */
  dynamic args; //: string | string[];

  /**
     * Channel.
     */
  Channel channel;

  /**
     * Replace_channel.
     */
  Channel? replace_channel;
  dynamic json;

  factory StasisStart.fromJson(dynamic json) {
    Channel channel = Channel.fromJson(json['channel']);
    return StasisStart(
        json['args'] as dynamic, channel as Channel, json as dynamic);
  }

  // @override
  // String toString() {
  //   return json;
  // }
}
