import 'dart:convert';

import 'package:deliverance_desktop/models/device_recommendation.dart';
import 'package:deliverance_desktop/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class RecommendationProvider extends BaseProvider<DeviceRecommendation> {
  RecommendationProvider() : super("Recommendation");

  @override
  DeviceRecommendation fromJson(data) {
    return DeviceRecommendation.fromJson(data);
  }

  Future<List<DeviceRecommendation>> getCriticalDevices({
    required int top,
    required double minProbability,
  }) async {
    final response = await sendWithRetry(() async {
      final queryString = getQueryString({
        'top': top,
        'minProbability': minProbability,
      });
      final uri = Uri.parse("${BaseProvider.baseUrl}$endpoint?$queryString");
      return await http.get(uri, headers: createHeaders());
    });

    final data = jsonDecode(response.body) as List;
    return data.map((e) => fromJson(e)).toList();
  }

  Future<RecommendationTraining> getTrainingInfo() async {
    final response = await sendWithRetry(() async {
      final uri = Uri.parse("${BaseProvider.baseUrl}$endpoint/Model");
      return await http.get(uri, headers: createHeaders());
    });
    return RecommendationTraining.fromJson(jsonDecode(response.body));
  }

  Future<RecommendationTraining> train() async {
    final response = await sendWithRetry(() async {
      final uri = Uri.parse("${BaseProvider.baseUrl}$endpoint/Train");
      return await http.post(uri, headers: createHeaders());
    });
    return RecommendationTraining.fromJson(jsonDecode(response.body));
  }

  Future<DeviceEvidence> getEvidence(int deviceId) async {
    final response = await sendWithRetry(() async {
      final uri = Uri.parse(
        "${BaseProvider.baseUrl}$endpoint/$deviceId/Evidence",
      );
      return await http.get(uri, headers: createHeaders());
    });

    return DeviceEvidence.fromJson(jsonDecode(response.body));
  }
}
