import 'dart:convert';
import 'dart:io';

import 'cdr.dart';

class DasboardClient {
  DasboardClient(Uri voice_records, Uri cdr_records)
      : voice_records = voice_records,
        cdr_records = cdr_records {
    print("Voice record: $voice_records");
    print("CDR records: $cdr_records");
  }

  Future<dynamic> send_cdr(Cdr cdr) async {
    var uri = Uri(
        scheme: cdr_records.scheme,
        userInfo: cdr_records.userInfo,
        host: cdr_records.host,
        port: cdr_records.port,
        path: cdr_records.path,
        //Iterable<String>? pathSegments,
        query: cdr_records.query,
        queryParameters: cdr.parse()
        //String? fragment
        );

    //dsvar uri = Uri.http(baseUrl, '/channels', qParams);
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    print(stringData);
    return (statusCode: response.statusCode, resp: stringData);
  }

  Future<dynamic> send_call_records(CallRecording cdr) async {
    var uri = Uri(
        scheme: voice_records.scheme,
        userInfo: voice_records.userInfo,
        host: voice_records.host,
        port: voice_records.port,
        path: voice_records.path,
        //Iterable<String>? pathSegments,
        query: voice_records.query,
        queryParameters: cdr.parse()
        //String? fragment
        );

    //dsvar uri = Uri.http(baseUrl, '/channels', qParams);
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    print(stringData);
    return (statusCode: response.statusCode, resp: stringData);
  }

  HttpClient client = HttpClient();

  Uri voice_records;
  Uri cdr_records;
}
