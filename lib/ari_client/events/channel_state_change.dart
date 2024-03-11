import '../ChannelsApi.dart';
import 'event.dart';

class ChannelStateChange extends Event {
  ChannelStateChange(this.channel, this.json) : super('ChannelStateChange');
  /**
     * Channel.
     */
  Channel channel; //: Channel;
  dynamic json;

  factory ChannelStateChange.fromJson(dynamic json) {
    Channel channel = Channel.fromJson(json['channel']);
    return ChannelStateChange(channel, json as dynamic);
  }
}
