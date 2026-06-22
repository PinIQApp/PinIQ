import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weight_models.dart';

class WeightApiService {
  WeightApiService({
    required this.baseUrl,
    required this.authToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String authToken;
  final http.Client _client;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse('$baseUrl$path').replace(
      queryParameters: query?.map(
        (key, value) => MapEntry(key, value?.toString()),
      ),
    );
  }

  Future<WeightLogEntry> createWeightLog({
    required int athleteId,
    required int teamId,
    required DateTime loggedAt,
    required double weight,
    double? bodyFatPercentage,
    String? hydrationNote,
    String? comments,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/weights/log'),
      headers: _headers,
      body: jsonEncode({
        'athlete_id': athleteId,
        'team_id': teamId,
        'logged_at': loggedAt.toIso8601String(),
        'weight': weight,
        'body_fat_percentage': bodyFatPercentage,
        'hydration_note': hydrationNote,
        'comments': comments,
      }),
    );
    _throwIfNeeded(response);
    return WeightLogEntry.fromMap(decodeObject(response.body));
  }

  Future<List<WeightLogEntry>> fetchWeightHistory({
    required int athleteId,
    required int teamId,
  }) async {
    final response = await _client.get(
      _uri('/api/v1/weights/history/$athleteId', {'team_id': teamId}),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return decodeList(response.body)
        .map(WeightLogEntry.fromMap)
        .toList(growable: false);
  }

  Future<WeightPlan> calculatePlan({
    required int athleteId,
    required int teamId,
    required double currentWeight,
    double? bodyFatPercentage,
    required double targetWeightClass,
    required DateTime targetDate,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/weights/plan/calculate'),
      headers: _headers,
      body: jsonEncode({
        'athlete_id': athleteId,
        'team_id': teamId,
        'current_weight': currentWeight,
        'body_fat_percentage': bodyFatPercentage,
        'target_weight_class': targetWeightClass,
        'target_date': targetDate.toIso8601String().split('T').first,
      }),
    );
    _throwIfNeeded(response);
    return WeightPlan.fromMap(decodeObject(response.body));
  }

  Future<WeightPlanBundle> fetchWeightPlan({
    required int athleteId,
    required int teamId,
  }) async {
    final response = await _client.get(
      _uri('/api/v1/weights/plan/$athleteId', {'team_id': teamId}),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return WeightPlanBundle.fromMap(decodeObject(response.body));
  }

  Future<List<AthleteWeightSnapshot>> fetchTeamDashboard({
    required int teamId,
    String? group,
    int? grade,
    String? weightClass,
  }) async {
    final response = await _client.get(
      _uri('/api/v1/weights/team-dashboard/$teamId', {
        if (group != null && group.isNotEmpty) 'group': group,
        if (grade != null) 'grade': grade,
        if (weightClass != null && weightClass.isNotEmpty) 'weight_class': weightClass,
      }),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return decodeList(response.body)
        .map(AthleteWeightSnapshot.fromMap)
        .toList(growable: false);
  }

  Future<List<WeightAlertItem>> fetchTeamAlerts({required int teamId}) async {
    final response = await _client.get(
      _uri('/api/v1/weights/alerts/$teamId'),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return decodeList(response.body)
        .map(WeightAlertItem.fromMap)
        .toList(growable: false);
  }

  Future<List<LinkedAthlete>> fetchLinkedAthletes() async {
    final response = await _client.get(
      _uri('/api/v1/weights/linked-athletes'),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return decodeList(response.body)
        .map(LinkedAthlete.fromMap)
        .toList(growable: false);
  }

  void _throwIfNeeded(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    String message = 'Weight service request failed.';
    try {
      final json = decodeObject(response.body);
      message = json['detail']?.toString() ?? message;
    } catch (_) {
      message = response.body.isNotEmpty ? response.body : message;
    }
    throw WeightApiException(message, response.statusCode);
  }
}

class WeightApiException implements Exception {
  const WeightApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => 'WeightApiException($statusCode): $message';
}
