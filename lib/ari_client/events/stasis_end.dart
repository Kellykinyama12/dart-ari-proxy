import '../ChannelsApi.dart';
import 'event.dart';

class StasisEnd extends Event {
  StasisEnd(this.channel, this.timestamp, this.json) : super('StasisEnd');
  /**
     * Channel.
     */
  DateTime timestamp;
  Channel channel; //: Channel;
  dynamic json;

  factory StasisEnd.fromJson(dynamic json) {
    Channel channel = Channel.fromJson(json['channel']);

    DateTime timestamp = DateTime.parse(json['timestamp']);
    return StasisEnd(channel, timestamp, json as dynamic);
  }
}
