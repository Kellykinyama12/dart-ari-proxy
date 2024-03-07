import 'dart:io';
import 'dart:convert';

import 'package:dart_ari_proxy/ari_client/ChannelsApi.dart';
import 'package:dart_ari_proxy/ari_client/resource.dart';

import 'models.dart';

class BridgesAPI {
  /**
   * Create an instance of the Bridges API client, providing access to the
   * `/bridges` endpoint.
   *
   * @param {object} params
   * @param {string} username The username to send with the request.
   * @param {string} password The password to send with the request.
   * @param {string} baseUrl The base url, without trailing slash,
   *  of the root Asterisk ARI endpoint. i.e. 'http://myserver.local:8088/ari'.
   */
  BridgesAPI() {}

  static Future<dynamic> list() async {
    //   var uri = Uri.http(baseUrl, '/bridges');

    var uri = Uri(
        scheme: "http",
        userInfo: "",
        host: "10.44.0.55",
        port: 8088,
        path: "ari/bridges",
        queryParameters: {'api_key': 'asterisk:asterisk'}
        //String? fragment
        );

    HttpClientRequest request = await client.getUrl(uri);
    HttpClientResponse response = await request.close();
    //print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    //print(response.statusCode);
    //print(stringData);
    return (statusCode: response.statusCode, resp: stringData);
  }

  static Future<dynamic> create(
      String? name, String? bridgeId, List<String>? type) async {
    var queryParams = {
      'name': name,
      'bridgeId': bridgeId,
      'type': type != null ? type.join(',') : "",
    };
    var uri = Uri(
        scheme: "http",
        userInfo: "",
        host: "10.44.0.55",
        port: 8088,
        path: "ari/bridges/${bridgeId ?? ""}",
        queryParameters: {
          'api_key': 'asterisk:asterisk',
          'bridgeId': bridgeId,
          'type': type != null ? type.join(',') : ""
        }
        //String? fragment
        );
    //var uri = Uri.http(baseUrl, '/bridges', queryParams);

    /// print(uri); // http://example.org/path?q=dart
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    //print(response);

    final String stringData = await response.transform(utf8.decoder).join();
    //print(response.statusCode);
    //print(stringData);
    return (statusCode: response.statusCode, resp: stringData);
  }

  static Future<dynamic> createOrUpdate(
      {String? name, String? bridgeId, List<String>? type}) async {
    var uri = Uri(
        scheme: "http",
        userInfo: "",
        host: "10.44.0.55",
        port: 8088,
        path: bridgeId != null ? "ari/bridges/$bridgeId" : "ari/bridges",
        // path: "ari/bridges${bridgeId!=null?bridgeId: ""}",
        queryParameters: {
          'api_key': 'asterisk:asterisk',
          'bridgeId': bridgeId,
          'type': type != null ? type.join(',') : ""
        }
        //String? fragment
        );

    //var queryParams = {'bridgeId': bridgeId, 'type': type.join(',')};

    // var uri = Uri.http(baseUrl, '/bridges/${bridgeId}', queryParams);

    /// print(uri); // http://example.org/path?q=dart
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    //print(response);

    final String stringData = await response.transform(utf8.decoder).join();
    //print(response.statusCode);
    //print(stringData);
    return (statusCode: response.statusCode, resp: stringData);
  }

  static Future<HttpClientResponse> get(String bridgeId) async {
    var queryParams = {
      'bridgeId': bridgeId,
      //'type': type.join(',')
    };

    var uri = Uri.http(baseUrl, '/bridges/${bridgeId}', queryParams);

    /// print(uri); // http://example.org/path?q=dart
    HttpClientRequest request = await client.getUrl(uri);
    HttpClientResponse response = await request.close();
    //print(response);

    final String stringData = await response.transform(utf8.decoder).join();
    //print(response.statusCode);
    //print(stringData);
    return response;
  }

  static Future<dynamic> destroy(String bridgeId) async {
    // var queryParams = {
    //   'bridgeId': bridgeId,
    //   //'type': type.join(',')
    // };

    var uri = Uri(
        scheme: "http",
        userInfo: "",
        host: "10.44.0.55",
        port: 8088,
        path: "ari/bridges/${bridgeId}",
        queryParameters: {'api_key': 'asterisk:asterisk'}
        //String? fragment
        );

    //var uri = Uri.http(baseUrl, '/bridges/${bridgeId}', queryParams);

    /// print(uri); // http://example.org/path?q=dart
    HttpClientRequest request = await client.deleteUrl(uri);
    HttpClientResponse response = await request.close();
    //print(response);

    final String stringData = await response.transform(utf8.decoder).join();
    //print(response.statusCode);
    //print(stringData);
    return (statusCode: response.statusCode, resp: stringData);
  }

  static Future<dynamic> addChannel(
      String bridgeId, List<String> channels) async {
    var queryParams = {
      //'bridgeId': bridgeId,
      'channel': channels.join(','),
      'role': ""
    };

    var uri = Uri(
        scheme: "http",
        userInfo: "",
        host: "10.44.0.55",
        port: 8088,
        path: "ari/bridges/${bridgeId}/addChannel",
        queryParameters: {
          'api_key': 'asterisk:asterisk',
          'channel': channels.join(',')
        }
        //String? fragment
        );

    //var uri = Uri.http(baseUrl, '/bridges/${bridgeId}/addChannel', queryParams);

    /// print(uri); // http://example.org/path?q=dart
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    //print(response);

    final String stringData = await response.transform(utf8.decoder).join();
    //print(response.statusCode);
    //print(stringData);
    return (statusCode: response.statusCode, resp: stringData);
  }

  static Future<dynamic> removeChannel(
      String bridgeId, List<String> channels) async {
    var queryParams = {
      //'bridgeId': bridgeId,
      'channel': channels.join(','),
      //'role':""
    };

    var uri = Uri(
        scheme: "http",
        userInfo: "",
        host: "10.44.0.55",
        port: 8088,
        path: "ari/bridges/${bridgeId}/removeChannel",
        queryParameters: {
          'api_key': 'asterisk:asterisk',
          'channel': channels.join(',')
        }
        //String? fragment
        );
    //var uri =
    //    Uri.http(baseUrl, '/bridges/${bridgeId}/removeChannel', queryParams);

    /// print(uri); // http://example.org/path?q=dart
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    //print(response);

    final String stringData = await response.transform(utf8.decoder).join();
    //print(response.statusCode);
    //print(stringData);
    return (statusCode: response.statusCode, resp: stringData);
  }

  static Future<dynamic> startMusicOnHold(String bridgeId) async {
    // var queryParams = {
    //   //'bridgeId': bridgeId,
    //   'channel': channels.join(','),
    //   //'role':""
    // };

    var uri = Uri(
        scheme: "http",
        userInfo: "",
        host: "10.44.0.55",
        port: 8088,
        path: "ari/bridges/${bridgeId}/moh",
        //String? fragment
        queryParameters: {'api_key': 'asterisk:asterisk'});

    //var uri = Uri.http(baseUrl, '/bridges/${bridgeId}/moh', queryParams);

    /// print(uri); // http://example.org/path?q=dart
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    //print(response);

    final String stringData = await response.transform(utf8.decoder).join();
    //print(response.statusCode);
    //print(stringData);
    return (statusCode: response.statusCode, resp: stringData);
    ;
  }

  static Future<HttpClientResponse> stopMusicOnHold(
      String bridgeId, List<String> channels) async {
    var queryParams = {
      //'bridgeId': bridgeId,
      'channel': channels.join(','),
      //'role':""
    };

    var uri = Uri.http(baseUrl, '/bridges/${bridgeId}/moh', queryParams);

    /// print(uri); // http://example.org/path?q=dart
    HttpClientRequest request = await client.deleteUrl(uri);
    HttpClientResponse response = await request.close();
    //print(response);

    final String stringData = await response.transform(utf8.decoder).join();
    //print(response.statusCode);
    //print(stringData);
    return response;
  }

  //   play(params = {}) {
  //   const {
  //     bridgeId,
  //     media,
  //     playbackId,
  //     lang,
  //     offsetms = 0,
  //     skipms = 3000,
  //   } = params;

  //   const id = encodeURIComponent(bridgeId);

  //   return this._request({
  //     method: "POST",
  //     url: `${this._baseUrl}/bridges/${id}/play`,
  //     params: {
  //       media: [].concat(media).join(","),
  //       lang,
  //       offsetms,
  //       skipms,
  //       playbackId,
  //     },
  //   });
  // }

  static Future<HttpClientResponse> play(
      String bridgeId, dynamic queryParams) async {
    var qParams = {
      'bridgeId': queryParams.bridgeId,
      'media': queryParams.media.join(','),
      'playbackId': "",
      'lang': "",
      'offsetms': "",
      'skipms': ""
    };

    var uri = Uri.http(
        baseUrl, '/bridges/${bridgeId}/play/${queryParams.playId}', qParams);

    /// print(uri); // http://example.org/path?q=dart
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    //print(response);

    final String stringData = await response.transform(utf8.decoder).join();
    //print(response.statusCode);
    //print(stringData);
    return response;
  }

  static Future<HttpClientResponse> record(
      String bridgeId, dynamic queryParams) async {
    var qParams = {
      'bridgeId': queryParams.bridgeId,
      'media': queryParams.media.join(','),
      'playbackId': "",
      'lang': "",
      'offsetms': "",
      'skipms': ""
    };

    var uri = Uri.http(baseUrl, '/bridges/${bridgeId}/record', qParams);

    /// print(uri); // http://example.org/path?q=dart
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    //print(response);

    final String stringData = await response.transform(utf8.decoder).join();
    //print(response.statusCode);
    //print(stringData);
    return response;
  }

  //Params params;
}

class Bridge extends Resource {
  Bridge(
      this.id,
      this.technology,
      this.bridge_type,
      this.bridge_class,
      this.creator,
      this.name,
      this.channels,
      this.video_mode,
      this.video_source_id,
      this.creationtime,
      this.json);
  /**
     * Unique identifier for this bridge.
     */
  String id; //: string;

  /**
     * Name of the current bridging technology.
     */
  String technology; //: string;

  /**
     * Type of bridge technology.
     */
  String bridge_type; //: string;

  /**
     * Bridging class.
     */
  String bridge_class; //: string;

  /**
     * Entity that created the bridge.
     */
  String creator; //: string;

  /**
     * Name the creator gave the bridge.
     */
  String name; //: string;

  /**
     * Ids of channels participating in this bridge.
     */
  List<dynamic> channels; //: string | string[];

  /**
     * The video mode the bridge is using. One of none, talker, or single.
     */
  String? video_mode; //?: string;

  /**
     * The ID of the channel that is the source of video in this bridge, if one exists.
     */
  String? video_source_id; //?: string;

  /**
     * Timestamp when bridge was created.
     */
  DateTime creationtime; //: Date;
  dynamic json;

  factory Bridge.fromJson(dynamic json) {
    //print(json['creationtime']);
    final creationtime = DateTime.parse(json['creationtime']); // 8:18pm
    return Bridge(
        json['id'] as String,
        json['technology'] as String,
        json['bridge_type'] as String,
        json['bridge_class'] as String,
        json['creator'] as String,
        json['name'] as String,
        json['channels'] as List<dynamic>,
        json['video_mode'] as String,
        json['video_source_id'] as String?,
        creationtime,
        json as dynamic);
  }

  addChannel(Function(bool) callback,
      {required List<String> channels,
      String? role,
      bool? absorbDTMF,
      bool? mute}) {
    BridgesAPI.addChannel(this.id, channels);
  }

  startMoh(Function(bool) callback) {}

  create(Function(bool, Bridge) callback,
      {String? type, String? bridgeId, String? name}) {
    List<String> types = [];
    if (type != null) types = type.split(',');

    var resp = BridgesAPI.create(name, id, types);
    resp.then((value) {
      print(value.resp);
      Bridge? brg = null;
      if (value.statusCode == 200) {
        //var bridgesJson = json.decode(value.resp);
        //brg = Bridge.fromJson(bridgesJson);
        callback(false, this);
      } else {
        // callback(true, brg!);
      }
    });
  }

  removeChannel(Function(bool) callback, {required List<String> channel}) {
    var resp = BridgesAPI.removeChannel(id, channel);
    resp.then((value) {
      if (value.statusCode != 404) {
        callback(false);
      }
    });
  }

  destroy(Function(bool) callback) {
    var resp = BridgesAPI.destroy(id);
    resp.then((value) {
      if (value.statusCode != 200 || value.statusCode != 204)
        callback(false);
      else
        callback(true);
    });
  }
}

class Bridges {
  list(Function(bool, List<Bridge>) callback) {
    var resp = BridgesAPI.list();

    resp.then((value) {
      //print(value.resp);
      List<Bridge> varBridges = [];
      if (value.statusCode != 404) {
        var bridgesJson = json.decode(value.resp);
        //print("Bridges: ${value.resp.runtimeType}");
        for (final e in bridgesJson) {
          // Do something with the current element
          //print(e);
          Bridge brige = Bridge.fromJson(e);
          varBridges.add(brige);
        }
        callback(false, varBridges);
      } else {
        callback(true, varBridges);
      }
    });
  }

  create(Function(bool, Bridge) callback,
      {String? type, String? bridgeId, String? name}) {
    List<String> types = [];
    if (type != null) types = type.split(',');

    var resp = BridgesAPI.create(name, bridgeId, types);
    resp.then((value) {
      //print(value.stringData);
      Bridge brg;
      if (value.statusCode != 404) {
        var bridgesJson = json.decode(value.resp);
        brg = Bridge.fromJson(bridgesJson);
        callback(false, brg);
      } else {
        //callback(true);
      }
    });
  }
}
