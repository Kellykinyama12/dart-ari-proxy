//import 'package:dart_ari_proxy/globals.dart';
import 'package:eloquent/eloquent.dart';

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
      required this.file_name,
      this.src,
      this.dst,
      this.clid,
      this.calldate,
      this.answerdate,
      this.hangupdate,
      this.duration,
      this.billsec,
      this.disposition});

  String? agent_number; //?: string;
  String? phone_number; //?: string;
  String? duration_number; //?: Ari.CallerID;
  String? file_name; //?: string;
  String? file_path; //?: Ari.CallerID;
  String? transcription; //?: string;

  String? src;
  String? dst;
  String? clid;
  String? calldate;
  String? answerdate;
  String? hangupdate;
  String? duration;
  String? billsec;
  String? disposition;

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

  Future<void> insertCallRecording() async {
    final manager = Manager();
    manager.addConnection({
      'driver': 'mysql',
      'host': '10.44.0.55',
      'port': '3306',
      'database': 'asterisk',
      'username': 'dashboard',
      'password': 'dashboard.123',
      // 'pool': true,
      // 'poolsize': 2,
    });
    manager.setAsGlobal();
    final db = await manager.connection();
    await db.table('recordings').insert({
      "agent_number": agent_number ?? "",
      "phone_number": phone_number ?? "",
      "duration_number": duration_number ?? "",
      "file_name": file_name ?? "",
      "file_path": file_path ?? "",

      'src': src ?? "",
      'dst': dst ?? "",
      'clid': clid ?? "",
      'calldate': calldate ?? "",
      'answerdate': answerdate ?? "",
      'hangupdate': hangupdate ?? "",
      'duration': duration ?? "",
      'billsec': billsec ?? "",
      'disposition': disposition ?? "",
      //"transcription": transcription ?? "",
      "created_at": DateTime.now().toString(),
      "updated_at": DateTime.now().toString(),
    });
    await db.disconnect();
  }
}
