import 'dart:io';
import 'dart:convert';

import 'models.dart';

class RecordingsApi{
  RecordingsApi() {

  }

  Future<HttpClientResponse> listStored() async {
    
  var uri = Uri.http(baseUrl, '/recordings/stored');
    HttpClientRequest request =
        await client.getUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  
  Future<HttpClientResponse> getStored(String name) async {
    
  var uri = Uri.http(baseUrl, '/recordings/stored/${name}');
    HttpClientRequest request =
        await client.getUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }


  Future<HttpClientResponse> destroyStored(String name) async {
    
  var uri = Uri.http(baseUrl, '/recordings/stored/${name}');
    HttpClientRequest request =
        await client.deleteUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  Future<HttpClientResponse> getStoredFile(String name) async {
    
  var uri = Uri.http(baseUrl, '/recordings/stored/${name}/file');
    HttpClientRequest request =
        await client.getUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  
  Future<HttpClientResponse> copyStored(String name) async {
    
  var uri = Uri.http(baseUrl, '/recordings/stored/${name}/copy');
    HttpClientRequest request =
        await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

 
  Future<HttpClientResponse> getLive(String name) async {
    
  var uri = Uri.http(baseUrl, '/recordings/live/${name}');
    HttpClientRequest request =
        await client.getUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

 
  Future<HttpClientResponse> cancel(String name) async {
    
  var uri = Uri.http(baseUrl, '/recordings/live/${name}');
    HttpClientRequest request =
        await client.deleteUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

   
  Future<HttpClientResponse> stop(String name) async {
    
  var uri = Uri.http(baseUrl, '/recordings/live/${name}/stop');
    HttpClientRequest request =
        await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }
   
  Future<HttpClientResponse> pause(String name) async {
    
  var uri = Uri.http(baseUrl, '/recordings/live/${name}/pause');
    HttpClientRequest request =
        await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }
  
  Future<HttpClientResponse> unpause(String name) async {
    
  var uri = Uri.http(baseUrl, '/recordings/live/${name}/pause');
    HttpClientRequest request =
        await client.deleteUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  
  Future<HttpClientResponse> mute(String name) async {
    
  var uri = Uri.http(baseUrl, '/recordings/live/${name}/mute');
    HttpClientRequest request =
        await client.postUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }

  Future<HttpClientResponse> unmute(String name) async {
    
  var uri = Uri.http(baseUrl, '/recordings/live/${name}/mute');
    HttpClientRequest request =
        await client.deleteUrl(uri);
    HttpClientResponse response = await request.close();
    print(response);
    final String stringData = await response.transform(utf8.decoder).join();
    print(response.statusCode);
    //print(stringData);
    return response;
  }
  //Params params;
}