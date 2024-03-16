import 'dart:async';

class CallerID {
  CallerID(this.name, this.number);
  /**
     * Name.
     */
  String name; //: string;

  /**
     * Number.
     */
  String number; //: string;

  factory CallerID.fromJson(dynamic json) {
    return CallerID(json['name'] as String, json['number'] as String);
  }
}

class Statistics {}

Timer setTimeout(callback, [int duration = 1000]) {
  return Timer(Duration(milliseconds: duration), callback);
}

void clearTimeout(Timer t) {
  t.cancel();
}
