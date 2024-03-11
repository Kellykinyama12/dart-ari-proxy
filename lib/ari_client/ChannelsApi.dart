import 'dart:io';
import 'dart:convert';

import 'package:dart_ari_proxy/ari_client/resource.dart';

//import 'events/event.dart';
import 'events/stasis_start.dart';
import 'misc.dart';
import 'models.dart';

class ChannelsApi {
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
  ChannelsApi() {}

  static Future<HttpClientResponse> list() async {
    // baseUrl.path = baseUrl.path + '/channels';
    var uri = Uri(
        scheme: "http",
        userInfo: "",
        host: "10.44.0.55",
        port: 8088,
        path: "ari/channels",
        //Iterable<String>? pathSegments,
        query: "",
        queryParameters: {'api_key': 'asterisk:asterisk'}
        //String? fragment
        );
    //var uri = Uri.http(baseUrl);
    HttpClientRequest request = await client.getUrl(uri);
    HttpClientResponse response = await request.close();
    //print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  static Future<dynamic> originate(
      {String? endpoint,
      String? extension,
      String? context,
      String? priority,
      String? label,
      String? app,
      List<String>? appArgs,
      String? callerId,
      num? timeout,
      String? channelId,
      String? otherChannelId,
      String? originator}) async {
    // params: {
    //     'endpoint':,
    //     'extension':,
    //     'context':,
    //     'priority':,
    //     'label':,
    //     'app':,
    //     'appArgs':,
    //     'callerId':,
    //     'timeout':,
    //     'channelId':,
    //     'otherChannelId':,
    //     'originator':,
    //     'formats': [].concat(formats).join(","),
    //   },
    //   data: { variables },
    var uri = Uri(
        scheme: "http",
        userInfo: "",
        host: "10.44.0.55",
        port: 8088,
        path: "ari/channels",
        //Iterable<String>? pathSegments,
        query: "",
        queryParameters: {
          'api_key': 'asterisk:asterisk',
          'endpoint': endpoint ?? "",
          'extension': extension ?? "",
          'context': context ?? "",
          'priority': priority ?? "",
          'label': label ?? "",
          'app': app ?? "",
          'appArgs': appArgs != null ? appArgs.join(",") : "",
          'callerId': callerId ?? "",
          'timeout': timeout ?? "",
          'channelId': channelId ?? "",
          'otherChannelId': otherChannelId ?? "",
          'originator': originator ?? "",
        }
        //String? fragment
        );

    //dsvar uri = Uri.http(baseUrl, '/channels', qParams);
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return (statusCode: response.statusCode, resp: stringData);
  }

  static Future<dynamic> create(
      {String? endpoint,
      String? extension,
      String? context,
      String? priority,
      String? label,
      String? app,
      List<String>? appArgs,
      String? callerId,
      String? timeout,
      String? channelId,
      String? otherChannelId,
      String? originator,
      dynamic variables}) async {
    // var uri = Uri.http(baseUrl, '/channels/create', query: "",
    //     queryParameters: {
    //   'api_key': 'asterisk:asterisk',
    //   'endpoint': queryParams.endpoint,
    //   'extension': queryParams.extension,
    //   'context': queryParams.context,
    //   'priority': queryParams.priority,
    //   'label': queryParams.label,
    //   'app': queryParams.app,
    //   'appArgs': queryParams.appArgs,
    //   'callerId': queryParams.callerId,
    //   'timeout': queryParams.timeout,
    //   'channelId': queryParams.channelId,
    //   'otherChannelId': queryParams.otherChannelId,
    //   'originator': queryParams.originator,
    // });

    var uri = Uri(
        scheme: "http",
        userInfo: "",
        host: "10.44.0.55",
        port: 8088,
        path: 'ari/channels/create',
        //Iterable<String>? pathSegments,
        query: "",
        queryParameters: {
          'api_key': 'asterisk:asterisk',
          'endpoint': endpoint ?? "",
          'extension': extension ?? "",
          'context': context ?? "",
          'priority': priority ?? "",
          'label': label ?? "",
          'app': app ?? "",
          'appArgs': appArgs != null ? appArgs.join(",") : "",
          'callerId': callerId ?? "",
          'timeout': timeout ?? "",
          'channelId': channelId ?? "",
          'otherChannelId': otherChannelId ?? "",
          'originator': originator ?? "",
          'variables': variables ?? ""
        });

    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return (statusCode: response.statusCode, resp: stringData);
  }

  static Future<dynamic> createWithId(
      {String? endpoint,
      String? extension,
      String? context,
      String? priority,
      String? label,
      String? app,
      List<String>? appArgs,
      String? callerId,
      String? timeout,
      String? channelId,
      String? otherChannelId,
      String? originator}) async {
    // var uri = Uri.http(baseUrl, '/channels/create', query: "",
    //     queryParameters: {
    //   'api_key': 'asterisk:asterisk',
    //   'endpoint': queryParams.endpoint,
    //   'extension': queryParams.extension,
    //   'context': queryParams.context,
    //   'priority': queryParams.priority,
    //   'label': queryParams.label,
    //   'app': queryParams.app,
    //   'appArgs': queryParams.appArgs,
    //   'callerId': queryParams.callerId,
    //   'timeout': queryParams.timeout,
    //   'channelId': queryParams.channelId,
    //   'otherChannelId': queryParams.otherChannelId,
    //   'originator': queryParams.originator,
    // });

    var uri = Uri(
        scheme: "http",
        userInfo: "",
        host: "10.44.0.55",
        port: 8088,
        path: 'ari/channels/create',
        //Iterable<String>? pathSegments,
        query: "",
        queryParameters: {
          'api_key': 'asterisk:asterisk',
          'endpoint': endpoint ?? "",
          'extension': extension ?? "",
          'context': context ?? "",
          'priority': priority ?? "",
          'label': label ?? "",
          'app': app ?? "",
          'appArgs': appArgs != null ? appArgs.join(",") : "",
          'callerId': callerId ?? "",
          'timeout': timeout ?? "",
          'channelId': channelId ?? "",
          'otherChannelId': otherChannelId ?? "",
          'originator': originator ?? "",
        });

    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return (statusCode: response.statusCode, resp: stringData);
  }

  static Future<HttpClientResponse> get(String channelId) async {
    // params: {
    //     'endpoint':,
    //     'extension':,
    //     'context':,
    //     'priority':,
    //     'label':,
    //     'app':,
    //     'appArgs':,
    //     'callerId':,
    //     'timeout':,
    //     'channelId':,
    //     'otherChannelId':,
    //     'originator':,
    //     'formats': [].concat(formats).join(","),
    //   },
    //   data: { variables },

    var uri = Uri.http(baseUrl, '/channels/${channelId}');
    HttpClientRequest request = await client.getUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  static Future<HttpClientResponse> originateWithId(
      String channelId, dynamic queryParams, qParams) async {
    // params: {
    //     'endpoint':,
    //     'extension':,
    //     'context':,
    //     'priority':,
    //     'label':,
    //     'app':,
    //     'appArgs':,
    //     'callerId':,
    //     'timeout':,
    //     'channelId':,
    //     'otherChannelId':,
    //     'originator':,
    //     'formats': [].concat(formats).join(","),
    //   },
    //   data: { variables },

    var uri = Uri.http(baseUrl, '/channels/${channelId}', qParams);
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  static Future<dynamic> hangup(String channelId) async {
    // params: {
    //     'endpoint':,
    //     'extension':,
    //     'context':,
    //     'priority':,
    //     'label':,
    //     'app':,
    //     'appArgs':,
    //     'callerId':,
    //     'timeout':,
    //     'channelId':,
    //     'otherChannelId':,
    //     'originator':,
    //     'formats': [].concat(formats).join(","),
    //   },
    //   data: { variables },
    var uri = Uri(
        scheme: "http",
        userInfo: "",
        host: "10.44.0.55",
        port: 8088,
        path: "ari/channels/${channelId}",
        //Iterable<String>? pathSegments,
        query: "",
        queryParameters: {'api_key': 'asterisk:asterisk'}
        //String? fragment
        );
    //var uri = Uri.http(baseUrl, '/channels/${channelId}');
    HttpClientRequest request = await client.deleteUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return (statusCode: response.statusCode, resp: stringData);
  }

  static Future<HttpClientResponse> continueInDialplan(
      String channelId, dynamic queryParams, qParams) async {
    // params: {
    //     'endpoint':,
    //     'extension':,
    //     'context':,
    //     'priority':,
    //     'label':,
    //     'app':,
    //     'appArgs':,
    //     'callerId':,
    //     'timeout':,
    //     'channelId':,
    //     'otherChannelId':,
    //     'originator':,
    //     'formats': [].concat(formats).join(","),
    //   },
    //   data: { variables },

    var uri = Uri.http(baseUrl, '/channels/${channelId}/continue', qParams);
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  static Future<HttpClientResponse> redirect(
      String channelId, dynamic queryParams, qParams) async {
    // params: {
    //     'endpoint':,
    //     'extension':,
    //     'context':,
    //     'priority':,
    //     'label':,
    //     'app':,
    //     'appArgs':,
    //     'callerId':,
    //     'timeout':,
    //     'channelId':,
    //     'otherChannelId':,
    //     'originator':,
    //     'formats': [].concat(formats).join(","),
    //   },
    //   data: { variables },

    var uri = Uri.http(baseUrl, '/channels/${channelId}/redirect', qParams);
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  static Future<HttpClientResponse> answer(String channelId,
      {dynamic queryParams, dynamic qParams}) async {
    // baseUrl.path = baseUrl.path + '/channels';
    var uri = Uri(
        scheme: "http",
        userInfo: "",
        host: "10.44.0.55",
        port: 8088,
        path: "ari/channels/$channelId/answer",
        //Iterable<String>? pathSegments,
        query: "",
        queryParameters: {'api_key': 'asterisk:asterisk'}
        //String? fragment
        );

//HttpClientRequest request = await client.getUrl(uri);
    //var uri = Uri.http(baseUrl, '/channels/${channelId}/answer', qParams);
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    //print(response);
    //final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  static Future<HttpClientResponse> ring(
      String channelId, dynamic queryParams, qParams) async {
    // params: {
    //     'endpoint':,
    //     'extension':,
    //     'context':,
    //     'priority':,
    //     'label':,
    //     'app':,
    //     'appArgs':,
    //     'callerId':,
    //     'timeout':,
    //     'channelId':,
    //     'otherChannelId':,
    //     'originator':,
    //     'formats': [].concat(formats).join(","),
    //   },
    //   data: { variables },

    var uri = Uri.http(baseUrl, '/channels/${channelId}/ring', qParams);
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  static Future<HttpClientResponse> ringStop(
      String channelId, dynamic queryParams, qParams) async {
    // params: {
    //     'endpoint':,
    //     'extension':,
    //     'context':,
    //     'priority':,
    //     'label':,
    //     'app':,
    //     'appArgs':,
    //     'callerId':,
    //     'timeout':,
    //     'channelId':,
    //     'otherChannelId':,
    //     'originator':,
    //     'formats': [].concat(formats).join(","),
    //   },
    //   data: { variables },

    var uri = Uri.http(baseUrl, '/channels/${channelId}/ring', qParams);
    HttpClientRequest request = await client.deleteUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  static Future<HttpClientResponse> sendDTMF(
      String channelId, dynamic queryParams, qParams) async {
    // params: {
    //     'endpoint':,
    //     'extension':,
    //     'context':,
    //     'priority':,
    //     'label':,
    //     'app':,
    //     'appArgs':,
    //     'callerId':,
    //     'timeout':,
    //     'channelId':,
    //     'otherChannelId':,
    //     'originator':,
    //     'formats': [].concat(formats).join(","),
    //   },
    //   data: { variables },

    var uri = Uri.http(baseUrl, '/channels/${channelId}/dtmf', qParams);
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  static Future<HttpClientResponse> mute(
      String channelId, dynamic queryParams, qParams) async {
    // params: {
    //     'endpoint':,
    //     'extension':,
    //     'context':,
    //     'priority':,
    //     'label':,
    //     'app':,
    //     'appArgs':,
    //     'callerId':,
    //     'timeout':,
    //     'channelId':,
    //     'otherChannelId':,
    //     'originator':,
    //     'formats': [].concat(formats).join(","),
    //   },
    //   data: { variables },

    var uri = Uri.http(baseUrl, '/channels/${channelId}/mute', qParams);
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  static Future<HttpClientResponse> unmute(
      String channelId, dynamic queryParams, qParams) async {
    // params: {
    //     'endpoint':,
    //     'extension':,
    //     'context':,
    //     'priority':,
    //     'label':,
    //     'app':,
    //     'appArgs':,
    //     'callerId':,
    //     'timeout':,
    //     'channelId':,
    //     'otherChannelId':,
    //     'originator':,
    //     'formats': [].concat(formats).join(","),
    //   },
    //   data: { variables },

    var uri = Uri.http(baseUrl, '/channels/${channelId}/mute', qParams);
    HttpClientRequest request = await client.deleteUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  static Future<HttpClientResponse> hold(
      String channelId, dynamic queryParams, qParams) async {
    // params: {
    //     'endpoint':,
    //     'extension':,
    //     'context':,
    //     'priority':,
    //     'label':,
    //     'app':,
    //     'appArgs':,
    //     'callerId':,
    //     'timeout':,
    //     'channelId':,
    //     'otherChannelId':,
    //     'originator':,
    //     'formats': [].concat(formats).join(","),
    //   },
    //   data: { variables },

    var uri = Uri.http(baseUrl, '/channels/${channelId}/hold', qParams);
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  static Future<HttpClientResponse> unhold(
      String channelId, dynamic queryParams, qParams) async {
    // params: {
    //     'endpoint':,
    //     'extension':,
    //     'context':,
    //     'priority':,
    //     'label':,
    //     'app':,
    //     'appArgs':,
    //     'callerId':,
    //     'timeout':,
    //     'channelId':,
    //     'otherChannelId':,
    //     'originator':,
    //     'formats': [].concat(formats).join(","),
    //   },
    //   data: { variables },

    var uri = Uri.http(baseUrl, '/channels/${channelId}/hold', qParams);
    HttpClientRequest request = await client.deleteUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  static Future<HttpClientResponse> startMusicOnHold(
      String channelId, dynamic queryParams, qParams) async {
    // params: {
    //     'endpoint':,
    //     'extension':,
    //     'context':,
    //     'priority':,
    //     'label':,
    //     'app':,
    //     'appArgs':,
    //     'callerId':,
    //     'timeout':,
    //     'channelId':,
    //     'otherChannelId':,
    //     'originator':,
    //     'formats': [].concat(formats).join(","),
    //   },
    //   data: { variables },

    var uri = Uri.http(baseUrl, '/channels/${channelId}/moh', qParams);
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  static Future<HttpClientResponse> stopMusicOnHold(
      String channelId, dynamic queryParams, qParams) async {
    // params: {
    //     'endpoint':,
    //     'extension':,
    //     'context':,
    //     'priority':,
    //     'label':,
    //     'app':,
    //     'appArgs':,
    //     'callerId':,
    //     'timeout':,
    //     'channelId':,
    //     'otherChannelId':,
    //     'originator':,
    //     'formats': [].concat(formats).join(","),
    //   },
    //   data: { variables },

    var uri = Uri.http(baseUrl, '/channels/${channelId}/moh', qParams);
    HttpClientRequest request = await client.deleteUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  static Future<HttpClientResponse> startSilence(
      String channelId, dynamic queryParams, qParams) async {
    // params: {
    //     'endpoint':,
    //     'extension':,
    //     'context':,
    //     'priority':,
    //     'label':,
    //     'app':,
    //     'appArgs':,
    //     'callerId':,
    //     'timeout':,
    //     'channelId':,
    //     'otherChannelId':,
    //     'originator':,
    //     'formats': [].concat(formats).join(","),
    //   },
    //   data: { variables },

    var uri = Uri.http(baseUrl, '/channels/${channelId}/silence', qParams);
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  static Future<HttpClientResponse> stopSilence(
      String channelId, dynamic queryParams, qParams) async {
    // params: {
    //     'endpoint':,
    //     'extension':,
    //     'context':,
    //     'priority':,
    //     'label':,
    //     'app':,
    //     'appArgs':,
    //     'callerId':,
    //     'timeout':,
    //     'channelId':,
    //     'otherChannelId':,
    //     'originator':,
    //     'formats': [].concat(formats).join(","),
    //   },
    //   data: { variables },

    var uri = Uri.http(baseUrl, '/channels/${channelId}/silence', qParams);
    HttpClientRequest request = await client.deleteUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  static Future<dynamic> play(String channelId, List<String> media) async {
    var uri = Uri(
        scheme: "http",
        userInfo: "",
        host: "10.44.0.55",
        port: 8088,
        path: "ari/channels/$channelId/play",
        //Iterable<String>? pathSegments,
        query: "",
        queryParameters: {
          'api_key': 'asterisk:asterisk',
          'media': media.join(","),
          'lang': "en",
          'offsetms': '0',
          'skipms': '3000'
        }
        //String? fragment
        );

    //var uri = Uri(baseUrl);
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    //return response;
    return (statusCode: response.statusCode, resp: stringData);
  }

  static Future<dynamic> playWithId(
      String channelId, String playbackId, List<String> media) async {
    // params: {
    //     'endpoint':,
    //     'extension':,
    //     'context':,
    //     'priority':,
    //     'label':,
    //     'app':,
    //     'appArgs':,
    //     'callerId':,
    //     'timeout':,
    //     'channelId':,
    //     'otherChannelId':,
    //     'originator':,
    //     'formats': [].concat(formats).join(","),
    //   },
    //   data: { variables },

    var uri = Uri(
        scheme: "http",
        userInfo: "",
        host: "10.44.0.55",
        port: 8088,
        path: "ari/channels/$channelId/play/$playbackId'",
        //Iterable<String>? pathSegments,
        query: "",
        queryParameters: {
          'api_key': 'asterisk:asterisk',
          'media': media.join(","),
          'lang': "en",
          'offsetms': '0',
          'skipms': '3000'
        }
        //String? fragment
        );

    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return (statusCode: response.statusCode, resp: stringData);
  }

  static Future<HttpClientResponse> record(
      String channelId, String playId, dynamic queryParams, qParams) async {
    // params: {
    //     'endpoint':,
    //     'extension':,
    //     'context':,
    //     'priority':,
    //     'label':,
    //     'app':,
    //     'appArgs':,
    //     'callerId':,
    //     'timeout':,
    //     'channelId':,
    //     'otherChannelId':,
    //     'originator':,
    //     'formats': [].concat(formats).join(","),
    //   },
    //   data: { variables },

    var uri = Uri.http(baseUrl, '/channels/${channelId}/record', qParams);
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  static Future<dynamic> getChannelVariable(
      String channelId, String variable) async {
    // params: {
    //     'endpoint':,
    //     'extension':,
    //     'context':,
    //     'priority':,
    //     'label':,
    //     'app':,
    //     'appArgs':,
    //     'callerId':,
    //     'timeout':,
    //     'channelId':,
    //     'otherChannelId':,
    //     'originator':,
    //     'formats': [].concat(formats).join(","),
    //   },
    //   data: { variables },

    var uri = Uri(
        scheme: "http",
        userInfo: "",
        host: "10.44.0.55",
        port: 8088,
        path: "ari/channels/${channelId}/variable",
        //Iterable<String>? pathSegments,
        query: "",
        queryParameters: {'api_key': 'asterisk:asterisk', 'variable': variable}
        //String? fragment
        );

    HttpClientRequest request = await client.getUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return (statusCode: response.statusCode, resp: stringData);
  }

  static Future<HttpClientResponse> setChannelVariable(
      String channelId, String playId, dynamic queryParams, qParams) async {
    // params: {
    //     'endpoint':,
    //     'extension':,
    //     'context':,
    //     'priority':,
    //     'label':,
    //     'app':,
    //     'appArgs':,
    //     'callerId':,
    //     'timeout':,
    //     'channelId':,
    //     'otherChannelId':,
    //     'originator':,
    //     'formats': [].concat(formats).join(","),
    //   },
    //   data: { variables },

    var uri = Uri.http(baseUrl, '/channels/${channelId}/variable', qParams);
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  static Future<HttpClientResponse> snoopChannel(
      String channelId, String sid, dynamic queryParams, qParams) async {
    // params: {
    //     'endpoint':,
    //     'extension':,
    //     'context':,
    //     'priority':,
    //     'label':,
    //     'app':,
    //     'appArgs':,
    //     'callerId':,
    //     'timeout':,
    //     'channelId':,
    //     'otherChannelId':,
    //     'originator':,
    //     'formats': [].concat(formats).join(","),
    //   },
    //   data: { variables },

    var uri = Uri.http(baseUrl, '/channels/${channelId}/snoop/${sid}', qParams);
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  static Future<dynamic> externalMedia({
    required String app, //: string;
    dynamic variables, //?: Containers;
    required String external_host, //: string;
    String? encapsulation, //?: string;
    String? transport, //?: string;
    String? connection_type, //?: string;
    required String format, //: string;
    String? direction, //?: string;
  }) async {
    // params: {
    //     'endpoint':,
    //     'extension':,
    //     'context':,
    //     'priority':,
    //     'label':,
    //     'app':,
    //     'appArgs':,
    //     'callerId':,
    //     'timeout':,
    //     'channelId':,
    //     'otherChannelId':,
    //     'originator':,
    //     'formats': [].concat(formats).join(","),
    //   },
    //   data: { variables },
    //POST /channels/externalMedia?app=MyApp&external_host=127.0.0.1%3A60000&format=ulaw
    print(variables);

    var uri = Uri(
      scheme: "http",
      userInfo: "",
      host: "10.44.0.55",
      port: 8088,
      path: "ari/channels/externalMedia",
      //Iterable<String>? pathSegments,
      query: "",
      queryParameters: {
        'api_key': 'asterisk:asterisk',
        'app': app,
        'variables': jsonEncode(variables),
        'external_host': external_host,
        'encapsulation': encapsulation,
        'transport': transport,
        'connection_type': connection_type,
        'format': format,
        'direction': direction
      },
      //String? fragment
    );
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return (statusCode: response.statusCode, resp: stringData);
  }

  static Future<HttpClientResponse> dial(
      String channelId, String sid, dynamic queryParams, qParams) async {
    // params: {
    //     'endpoint':,
    //     'extension':,
    //     'context':,
    //     'priority':,
    //     'label':,
    //     'app':,
    //     'appArgs':,
    //     'callerId':,
    //     'timeout':,
    //     'channelId':,
    //     'otherChannelId':,
    //     'originator':,
    //     'formats': [].concat(formats).join(","),
    //   },
    //   data: { variables },

    var uri = Uri.http(baseUrl, '/channels/${channelId}/dial', qParams);
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

//typedef MyCallback = void Function(int value);

class Channel extends Resource {
  Channel(
      this.id,
      this.name,
      this.accountcode,
      this.state,
      this.caller,
      this.dialplan,
      this.creationtime,
      this.language,
      this.channelvars,
      this.json) {}
  String id;
  String name;
  String state; //: string;
  CallerID caller; //: CallerID;

  /**
     * Connected.
     */
  dynamic connected; //: CallerID;

  /**
     * Accountcode.
     */
  String accountcode; //: string;

  /**
     * Current location in the dialplan.
     */
  dynamic dialplan; //: DialplanCEP;

  /**
     * Timestamp when channel was created.
     */
  DateTime creationtime; //: Date;

  /**
     * The default spoken language.
     */
  String language; //: string;

  /**
     * Channel variables.
     */
  dynamic channelvars; //?: IndexableObject;

  dynamic json;

  factory Channel.fromJson(dynamic json) {
    //print(json);
    final creationtime = DateTime.parse(json['creationtime']); // 8:18pm
    var caller = CallerID.fromJson(json['caller']);
    return Channel(
        json['id'] as String,
        json['name'] as String,
        json['accountcode'] as String,
        json['state'] as String,
        caller as CallerID,
        json['dialplan'] as dynamic,
        creationtime as DateTime,
        json['language'] as String,
        json['channelvars'] as dynamic,
        json as dynamic);
  }

//final void Function(Error) callback;

  void answer(Function(bool) callback) {
    var resp = ChannelsApi.answer(id);
    resp.then((value) {
      print("Status code: ${value.statusCode}");
      bool err = value.statusCode == 404 ||
          value.statusCode == 409 ||
          value.statusCode == 412;

      callback.call(err); // Example usage
    });
  }

  // @override
  // String toString() {
  //   return json;
  // }

  Map<String, Function(dynamic event, Channel channel)> handlers = {};

  void on(String event, Function(dynamic event, Channel channel) callback) {
    //print("Adding channel event handler for $event");
    handlers[event] = callback;
  }

  void emit(data) {
    //print(data);

    if (handlers[data['type']] != null) {
      switch (data['type']) {
        case "StasisStart":
          print("Executing channel event ${data['type']}");
          Channel channel = Channel.fromJson(data['channel']);
          StasisStart stasisStart = StasisStart.fromJson(data);
          handlers[data['type']]!(stasisStart, channel);
      }
      //handlers[data['type']]!(data);
    }
  }

  removeAllListeners(String event) {}

  continueInDialplan(Function(dynamic event) callback,
      {String? context, String? extension, num? priority, String? label}) {}

  originate(Function(bool, Channel) callback,
      {required String endpoint, //: string;
      String? extension, //?: string;
      String? context, //?: string;
      String? priority, //?: number;
      String? label, //?: string;
      String? app, //?: string;
      List<String>? appArgs, //?: string;
      String? callerId, //?: string;
      num? timeout, //?: number;
      dynamic? variables, //?: Containers;
      String? otherChannelId, //?: string;
      String? originator, //?: string;
      String? formats //?: string;
      }) {
    ChannelsApi.originate(
        endpoint: endpoint, //: string;
        extension: extension, //?: string;
        context: context, //?: string;
        priority: priority, //?: number;
        label: label, //?: string;
        app: app, //?: string;
        appArgs: appArgs, //?: string;
        callerId: callerId, //?: string;
        timeout: timeout, //?: number;
        //variables:variables, //?: Containers;
        otherChannelId: otherChannelId, //?: string;
        originator: originator, //?: string;
        channelId: id
        //formats:formats //?: string;
        );
  }

  hangup(Function(bool) callback) {
    ChannelsApi.hangup(id);
  }

  // Future<Channel> externalMedia(
  //   Function(bool, Channel) callback, {
  //   required String app, //: string;
  //   dynamic variables, //?: Containers;
  //   required external_host, //: string;
  //   String? encapsulation, //?: string;
  //   String? transport, //?: string;
  //   String? connection_type, //?: string;
  //   required String format, //: string;
  //   String? direction, //?: string;
  // }) async {
  //   var resp = await ChannelsApi.externalMedia(
  //       app: app,
  //       variables: variables,
  //       external_host: external_host,
  //       encapsulation: encapsulation,
  //       transport: transport,
  //       connection_type: connection_type,
  //       format: format,
  //       direction: direction);

  //   print(resp.resp);

  //   var channelJson = resp.resp;

  //   Channel channel = Channel.fromJson(jsonDecode(channelJson));

  //   statisChannels[channel.id] = channel;
  //   return channel;

  //   // resp.then((value) {
  //   //   if (value.statusCode == 200 || value.statusCode == 204)
  //   //     callback(false, this);
  //   //   else
  //   //     callback(true, this);
  //   // });
  // }

  getChannelVar(Function(bool, dynamic) callback, String variable) {
    var resp = ChannelsApi.getChannelVariable(id, variable);
    resp.then((value) {
      print("Channel variable: ${value.resp}");
      //var varJson = jsonDecode(value.resp);
      //throw "You need to see cahnnel Variable";
      if (value.resp == '{"message":"Provided variable was not found"}')
        callback(true, value.resp);
      else {
        //callback(false, value.resp);
        throw value.resp;
      }
    });
  }
}
