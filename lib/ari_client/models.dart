import 'dart:io';
import 'dart:convert';

String username = "asterisk";
String password = "asterisk";

dynamic baseUrl = //

    (
  scheme: "http",
  userInfo: "",
  host: "10.44.0.55",
  port: 8088,
  path: "ari",
  //Iterable<String>? pathSegments,
  query: "",
  queryParameters: {'api_key': 'asterisk:asterisk'}
  //String? fragment
);
HttpClient client = HttpClient();
