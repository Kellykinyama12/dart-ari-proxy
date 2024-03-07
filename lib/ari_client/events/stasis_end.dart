import '../ChannelsApi.dart';
import 'event.dart';

class StasisEnd extends Event {
  StasisEnd(this.channel, this.json) : super('StasisEnd');
  /**
     * Channel.
     */
  Channel channel; //: Channel;
  dynamic json;

  factory StasisEnd.fromJson(dynamic json) {
    Channel channel = Channel.fromJson(json['channel']);
    return StasisEnd(channel as Channel, json as dynamic);
  }
}
