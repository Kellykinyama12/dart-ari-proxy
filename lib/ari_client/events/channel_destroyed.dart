import '../ChannelsApi.dart';
import 'event.dart';

class ChannelDestroyed extends Event {
  ChannelDestroyed(this.cause, this.cause_txt, this.channel, this.json)
      : super("ChannelDestroyed");
  /**
     * Integer representation of the cause of the hangup.
     */
  num cause; //: number;

  /**
     * Text representation of the cause of the hangup.
     */
  String cause_txt; //: string;

  /**
     * Channel.
     */
  Channel channel; //: Channel;

  dynamic json;

  factory ChannelDestroyed.fromJson(dynamic json) {
    Channel channel = Channel.fromJson(json['channel']);
    return ChannelDestroyed(json['cause'] as num, json['cause_txt'] as String,
        channel as Channel, json as dynamic);
  }
}
