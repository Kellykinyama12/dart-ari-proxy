import 'dart:io';
import 'dart:convert';

import 'models.dart';

class PlaybackApi {
  PlaybackApi() {}

  Future<HttpClientResponse> get(String id) async {
    var uri = Uri.http(baseUrl, '/playbacks/${id}');
    HttpClientRequest request = await client.getUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  Future<dynamic> stop(String playbackId) async {
    var uri = Uri(
        scheme: "http",
        userInfo: "",
        host: "10.44.0.55",
        port: 8088,
        path: "ari/playbacks/$playbackId",
        //Iterable<String>? pathSegments,
        query: "",
        queryParameters: {'api_key': 'asterisk:asterisk'}
        //String? fragment
        );

    //var uri = Uri.http(baseUrl, '/playbacks/${id}');
    HttpClientRequest request = await client.deleteUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return (statusCode: response.statusCode, resp: stringData);
  }

  Future<HttpClientResponse> control(String id) async {
    var uri = Uri.http(baseUrl, '/playbacks/${id}/control');
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  //Params params;
}
