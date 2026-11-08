import 'dart:convert';

import 'package:deliverance_mobile/models/search_result.dart';
import 'package:deliverance_mobile/providers/auth_provider.dart';
import 'package:deliverance_mobile/utils/api_client_exception.dart';
import 'package:deliverance_mobile/utils/api_constants.dart';
import 'package:deliverance_mobile/utils/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

abstract class BaseProvider<T> with ChangeNotifier {
  static final String _baseUrl = ApiConstants.baseUrl;

  static String? get baseUrl => _baseUrl;
  T? _data;
  T? get data => _data;
  bool get hasData => _data != null;

  final String endpoint;

  BaseProvider(this.endpoint);

  Future<SearchResult<T>> get({dynamic filter}) async {
    var url = "$_baseUrl$endpoint";
    if (filter != null) {
      var queryString = getQueryString(filter);
      url = "$url?$queryString";
    }
    var uri = Uri.parse(url);

    final response = await sendWithRetry(() async {
      var headers = createHeaders();
      return await http.get(uri, headers: headers);
    });

    var data = jsonDecode(response.body);

    var result = SearchResult<T>();

    result.totalCount = data['totalCount'];
    result.items = List<T>.from(data["items"].map((e) => fromJson(e)));

    return result;
  }

  Future<T> getById(int id) async {
    var url = "$_baseUrl$endpoint/$id";
    var uri = Uri.parse(url);

    final response = await sendWithRetry(() async {
      var headers = createHeaders();
      return await http.get(uri, headers: headers);
    });

    var data = jsonDecode(response.body);
    final parsed = fromJson(data);
    setData(parsed);
    return parsed;
  }

  Future<T> insert(dynamic request) async {
    var url = "$_baseUrl$endpoint";
    var uri = Uri.parse(url);
    var jsonRequest = jsonEncode(request);

    final response = await sendWithRetry(() async {
      var headers = createHeaders();
      return await http.post(uri, headers: headers, body: jsonRequest);
    });

    var data = jsonDecode(response.body);
    final parsed = fromJson(data);
    setData(parsed);
    return parsed;
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
    await sendWithRetry(() async {
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
        // Always UTC, like every other time sent to the API.
        query += '$prefix$key=${value.toUtc().toIso8601String()}';
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

      if (response.statusCode == 401) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
        throw ApiClientException(
          'Your session has expired. Please sign in again.',
        );
      }
    }
    validateResponse(response);

    return response;
  }
}
