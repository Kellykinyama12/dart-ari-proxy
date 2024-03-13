class Cdr {
  Cdr({
    this.accountcode, //?: string,
    this.src, //?: string,
    this.dst, //?: Ari.CallerID,
    this.dcontext, //?: string,
    this.clid, //?: Ari.CallerID,
    this.channel, //?: string,
    this.dstchannel, //?: string,
    this.lastapp, //?: string,
    this.lastdata, //?: string,
    this.calldate, //?: Date,
    this.answerdate, //?: Date,
    this.hangupdate, //?: Date,
    this.duration, //?: string,
    this.billsec, //?: string,
    this.disposition, //?: string,
    this.amaflags, //?: string,
    this.uniqueid, //?: string,
    this.userfield, //?: string,
  });

  String? accountcode; //?: string;
  String? src; //?: string;
  String? dst; //?: Ari.CallerID;
  String? dcontext; //?: string;
  String? clid; //?: Ari.CallerID;
  String? channel; //?: string;
  String? dstchannel; //?: string;
  String? lastapp; //?: string;
  String? lastdata; //?: string;
  String? calldate; //?: Date;
  String? answerdate; //?: Date;
  String? hangupdate; //?: Date;
  String? duration; //?: string;
  String? billsec; //?: string;
  String? disposition; //?: string;
  String? amaflags; //?: string;
  String? uniqueid; //?: string;
  String? userfield; //?: string;

  Map<String, String> parse() {
    return {
      "accountcode": accountcode ?? "",
      "src": src ?? "",
      "dst": dst ?? "",
      "dcontext": dcontext ?? "",
      "clid": clid ?? "",
      "channel": channel ?? "",
      "dstchannel": dstchannel ?? "",
      "lastapp": lastapp ?? "",
      "lastdata": lastdata ?? "",
      "calldate": calldate ?? "",
      "answerdate": answerdate ?? "",
      "hangupdate": hangupdate ?? "",
      "duration": duration ?? "",
      "billsec": billsec ?? "",
      "disposition": disposition ?? "",
      "amaflags": amaflags ?? "",
      "uniqueid": uniqueid ?? "",
      "userfield": userfield ?? "",
    };
  }
}

class CallRecording {
  CallRecording(
      {required this.agent_number,
      required this.phone_number,
      required this.file_path,
      required this.file_name});

  String? agent_number; //?: string;
  String? phone_number; //?: string;
  String? duration_number; //?: Ari.CallerID;
  String? file_name; //?: string;
  String? file_path; //?: Ari.CallerID;
  String? transcription; //?: string;

  Map<String, String> parse() {
    return {
      "agent_number": agent_number ?? "",
      "phone_number": phone_number ?? "",
      "duration_number": duration_number ?? "",
      "file_name": file_name ?? "",
      "file_path": file_path ?? "",
      "transcription": transcription ?? "",
    };
  }
}
