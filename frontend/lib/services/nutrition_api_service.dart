import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/nutrition_models.dart';

class NutritionApiService {
  NutritionApiService({
    required this.baseUrl,
    this.authToken,
  });

  final String baseUrl;
  final String? authToken;
  static const Duration _requestTimeout = Duration(seconds: 12);

  Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  Future<NutritionPlanResponseModel> createPlan({
    required Map<String, dynamic> payload,
  }) async {
    late final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/nutrition/plan'),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(_requestTimeout);
    } on SocketException {
      throw Exception(
        'Cannot reach the nutrition server at $baseUrl. Make sure the backend is running and reachable from the app.',
      );
    } on HttpException catch (error) {
      throw Exception('Nutrition request failed: ${error.message}');
    } on http.ClientException {
      if (kIsWeb &&
          Uri.base.scheme == 'https' &&
          baseUrl.startsWith('http://')) {
        throw Exception(
          'The app is loaded over HTTPS but the API URL is HTTP ($baseUrl). Use an HTTPS API URL.',
        );
      }
      throw Exception(
        'The browser blocked the nutrition request. Check the API URL ($baseUrl), CORS, and backend status.',
      );
    } on TimeoutException {
      throw Exception(
        'The nutrition server took too long to respond. Check that the backend is running.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = _errorDetail(response.body);
      throw Exception(detail ?? 'Failed to create nutrition plan.');
    }

    try {
      return NutritionPlanResponseModel.fromJson(
        Map<String, dynamic>.from(jsonDecode(response.body)),
      );
    } on FormatException {
      throw Exception(
          'The nutrition server returned a response the app could not read.');
    }
  }

  String? _errorDetail(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        final detail = data['detail'];
        if (detail is String && detail.trim().isNotEmpty) return detail;
      }
    } on FormatException {
      return null;
    }
    return null;
  }
}
