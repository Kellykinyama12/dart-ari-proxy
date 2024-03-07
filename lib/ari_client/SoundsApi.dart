import 'dart:io';
import 'dart:convert';

import 'models.dart';

class SoundsApi {
  SoundsApi(){}

  Future<HttpClientResponse> listStored() async {
    
  var uri = Uri.http(baseUrl, '/sounds');
    HttpClientRequest request =
        await client.getUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }
  
  Future<HttpClientResponse> get(String soundId) async {
    
  var uri = Uri.http(baseUrl, '/sounds/${soundId}');
    HttpClientRequest request =
        await client.getUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  //Params params;
}
