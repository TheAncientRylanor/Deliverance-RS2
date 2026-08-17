import 'dart:convert';

import 'package:deliverance_mobile/models/search_result.dart';
import 'package:deliverance_mobile/providers/auth_provider.dart';
import 'package:deliverance_mobile/utils/api_client_exception.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

abstract class BaseProvider<T> with ChangeNotifier {
  static String? _baseUrl;

  static String? get baseUrl => _baseUrl;
  T? _data;
  T? get data => _data;
  bool get hasData => _data != null;

  final String endpoint;

  BaseProvider(this.endpoint) {
    _baseUrl = const String.fromEnvironment(
      "baseUrl",
      defaultValue: "http://10.0.2.2:5095/",
    );
  }

  Future<SearchResult<T>> get({dynamic filter}) async {
    var url = "$_baseUrl$endpoint";
    if (filter != null) {
      var queryString = getQueryString(filter);
      url = "$url?$queryString";
    }

    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.get(uri, headers: headers);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);

      var result = SearchResult<T>();

      result.totalCount = data['totalCount'];
      result.items = List<T>.from(data["items"].map((e) => fromJson(e)));

      return result;
    } else {
      throw new Exception("Unknown error");
    }
  }

  Future<T> getById(int id) async {
    var url = "$_baseUrl$endpoint/$id";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    http.Response response = await http.get(uri, headers: headers);

    validateResponse(response);
    var data = jsonDecode(response.body);
    final parsed = fromJson(data);
    setData(parsed);
    return parsed;
  }

  Future<T> insert(dynamic request) async {
    var url = "$_baseUrl$endpoint";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var jsonRequest = jsonEncode(request);
    var response = await http.post(uri, headers: headers, body: jsonRequest);
    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      final parsed = fromJson(data);
      setData(parsed);
      return parsed;
    } else {
      throw Exception("Unknown error");
    }
  }

  Future<T> update(int id, [dynamic request]) async {
    final response = await sendWithRetry(() async {
      var url = "$_baseUrl$endpoint/$id";
      var uri = Uri.parse(url);
      var headers = createHeaders();
      var jsonRequest = jsonEncode(request);
      return await http.put(uri, headers: headers, body: jsonRequest);
    });
    var data = jsonDecode(response.body);
    final parsed = fromJson(data);
    setData(parsed);
    return parsed;
  }

  Future remove(int id) async {
    final response = await sendWithRetry(() async {
      var url = "$_baseUrl$endpoint/$id";
      var uri = Uri.parse(url);
      var headers = createHeaders();
      return await http.delete(uri, headers: headers);
    });
  }

  void setData(T data) {
    _data = data;
    notifyListeners();
  }

  void clearData() {
    _data = null;
    notifyListeners();
  }

  T fromJson(data) {
    throw Exception("Method not implemented");
  }

  bool isValidResponse(Response response) {
    if (response.statusCode < 299) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized");
    } else {
      throw Exception("Something bad happened please try again");
    }
  }

  void validateResponse(Response response) {
    if (response.statusCode < 299) {
      return;
    }
    if (response.statusCode == 401) {
      throw ApiClientException(
        'Your session has expired. Please sign in again.',
      );
    }

    final parsed = ApiErrorParser.messageFromBody(response.body);
    if (response.statusCode >= 500) {
      throw ApiClientException(
        parsed ?? 'Server error. Please try again later.',
      );
    }

    throw ApiClientException(
      parsed ?? 'Request could not be completed. Please try again.',
    );
  }

  Map<String, String> createHeaders() {
    String accesstoken = AuthProvider.accesstoken ?? "";

    String basicAuth = "Bearer $accesstoken";

    var headers = {
      "Content-Type": "application/json",
      "Authorization": basicAuth,
    };

    return headers;
  }

  String getQueryString(
    Map params, {
    String prefix = '&',
    bool inRecursion = false,
  }) {
    String query = '';
    params.forEach((key, value) {
      if (inRecursion) {
        if (key is int) {
          key = '[$key]';
        } else if (value is List || value is Map) {
          key = '.$key';
        } else {
          key = '.$key';
        }
      }
      if (value is String || value is int || value is double || value is bool) {
        var encoded = value;
        if (value is String) {
          encoded = Uri.encodeComponent(value);
        }
        query += '$prefix$key=$encoded';
      } else if (value is DateTime) {
        query += '$prefix$key=${value.toIso8601String()}';
      } else if (value is List || value is Map) {
        if (value is List) value = value.asMap();
        value.forEach((k, v) {
          query += getQueryString(
            {k: v},
            prefix: '$prefix$key',
            inRecursion: true,
          );
        });
      }
    });
    return query;
  }

  Future<http.Response> sendWithRetry(
    Future<http.Response> Function() requestFn,
  ) async {
    http.Response response = await requestFn();

    if (response.statusCode == 401) {
      final success = await AuthProvider.instance.refreshToken();

      if (success) {
        response = await requestFn();
      }
    }
    validateResponse(response);

    return response;
  }
}
