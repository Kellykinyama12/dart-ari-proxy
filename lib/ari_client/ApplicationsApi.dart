import 'dart:io';
import 'dart:convert';
import 'models.dart';

class ApplicationsApi {
  ApplicationsApi() {}

  Future<HttpClientResponse> list() async {
    var uri = Uri.http(baseUrl, '/applications');
    HttpClientRequest request = await client.getUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  Future<HttpClientResponse> get(String app) async {
    var uri = Uri.http(baseUrl, '/applications/${app}');
    HttpClientRequest request = await client.getUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  Future<HttpClientResponse> subscribe(String app) async {
    var uri = Uri.http(baseUrl, '/applications/${app}/subscription');
    HttpClientRequest request = await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  Future<HttpClientResponse> unsubscribe(String app) async {
    var uri = Uri.http(baseUrl, '/applications/${app}/subscription');
    HttpClientRequest request = await client.deleteUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  Future<HttpClientResponse> filterEvents(String app) async {
    var uri = Uri.http(baseUrl, '/applications/${app}/eventFilter');
    HttpClientRequest request = await client.putUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  //Params params;
}
