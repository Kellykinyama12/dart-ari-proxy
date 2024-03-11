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
