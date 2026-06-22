import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/stats_models.dart';

class StatsApiService {
  StatsApiService({
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

  Future<MatchEntry> createMatch({
    required int athleteId,
    required int teamId,
    required String opponentName,
    String? opponentSchool,
    String? eventName,
    required DateTime matchDate,
    required String weightClass,
    required MatchOutcome result,
    required MatchResultType resultType,
    required int scoreFor,
    required int scoreAgainst,
    String? pinTime,
    String? notes,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/matches'),
      headers: _headers,
      body: jsonEncode({
        'athlete_id': athleteId,
        'team_id': teamId,
        'opponent_name': opponentName,
        'opponent_school': opponentSchool,
        'event_name': eventName,
        'match_date': matchDate.toIso8601String().split('T').first,
        'weight_class': weightClass,
        'result': matchOutcomeToApi(result),
        'result_type': matchResultTypeToApi(resultType),
        'score_for': scoreFor,
        'score_against': scoreAgainst,
        'pin_time': pinTime,
        'notes': notes,
      }),
    );
    _throwIfNeeded(response);
    return MatchEntry.fromMap(decodeStatsObject(response.body));
  }

  Future<MatchStatLine> saveMatchStats({
    required int matchId,
    required int takedowns,
    required int escapes,
    required int reversals,
    required int nearfallPoints,
    required int stallCalls,
    int? rideTimeSeconds,
    int? shotAttempts,
    int? shotConversions,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/matches/$matchId/stats'),
      headers: _headers,
      body: jsonEncode({
        'takedowns': takedowns,
        'escapes': escapes,
        'reversals': reversals,
        'nearfall_points': nearfallPoints,
        'stall_calls': stallCalls,
        'ride_time_seconds': rideTimeSeconds,
        'shot_attempts': shotAttempts,
        'shot_conversions': shotConversions,
      }),
    );
    _throwIfNeeded(response);
    return MatchStatLine.fromMap(decodeStatsObject(response.body));
  }

  Future<MatchEntry> createFullMatchEntry({
    required int athleteId,
    required int teamId,
    required String opponentName,
    String? opponentSchool,
    String? eventName,
    required DateTime matchDate,
    required String weightClass,
    required MatchOutcome result,
    required MatchResultType resultType,
    required int scoreFor,
    required int scoreAgainst,
    String? pinTime,
    String? notes,
    int takedowns = 0,
    int escapes = 0,
    int reversals = 0,
    int nearfallPoints = 0,
    int stallCalls = 0,
    int? rideTimeSeconds,
    int? shotAttempts,
    int? shotConversions,
  }) async {
    final match = await createMatch(
      athleteId: athleteId,
      teamId: teamId,
      opponentName: opponentName,
      opponentSchool: opponentSchool,
      eventName: eventName,
      matchDate: matchDate,
      weightClass: weightClass,
      result: result,
      resultType: resultType,
      scoreFor: scoreFor,
      scoreAgainst: scoreAgainst,
      pinTime: pinTime,
      notes: notes,
    );
    final stats = await saveMatchStats(
      matchId: match.id,
      takedowns: takedowns,
      escapes: escapes,
      reversals: reversals,
      nearfallPoints: nearfallPoints,
      stallCalls: stallCalls,
      rideTimeSeconds: rideTimeSeconds,
      shotAttempts: shotAttempts,
      shotConversions: shotConversions,
    );
    return MatchEntry(
      id: match.id,
      athleteId: match.athleteId,
      teamId: match.teamId,
      createdByUserId: match.createdByUserId,
      updatedByUserId: match.updatedByUserId,
      opponentName: match.opponentName,
      opponentSchool: match.opponentSchool,
      eventName: match.eventName,
      matchDate: match.matchDate,
      weightClass: match.weightClass,
      result: match.result,
      resultType: match.resultType,
      scoreFor: match.scoreFor,
      scoreAgainst: match.scoreAgainst,
      scoreDisplay: match.scoreDisplay,
      pinTime: match.pinTime,
      notes: match.notes,
      createdAt: match.createdAt,
      updatedAt: match.updatedAt,
      stats: stats,
    );
  }

  Future<AthleteStatsDashboard> fetchAthleteStats({
    required int athleteId,
    required int teamId,
  }) async {
    final response = await _client.get(
      _uri('/api/v1/stats/athlete/$athleteId', {'team_id': teamId}),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return AthleteStatsDashboard.fromMap(decodeStatsObject(response.body));
  }

  Future<AthleteRecentBundle> fetchAthleteRecent({
    required int athleteId,
    required int teamId,
  }) async {
    final response = await _client.get(
      _uri('/api/v1/stats/athlete/$athleteId/recent', {'team_id': teamId}),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return AthleteRecentBundle.fromMap(decodeStatsObject(response.body));
  }

  Future<TeamStatsDashboard> fetchTeamStats({required int teamId}) async {
    final response = await _client.get(
      _uri('/api/v1/stats/team/$teamId'),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return TeamStatsDashboard.fromMap(decodeStatsObject(response.body));
  }

  Future<TeamLeaders> fetchTeamLeaders({required int teamId}) async {
    final response = await _client.get(
      _uri('/api/v1/stats/team/$teamId/leaders'),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return TeamLeaders.fromMap(decodeStatsObject(response.body));
  }

  Future<List<MatchEntry>> fetchTeamMatches({
    required int teamId,
    int? athleteId,
    String? eventName,
    String? weightClass,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final response = await _client.get(
      _uri('/api/v1/matches/team/$teamId', {
        if (athleteId != null) 'athlete_id': athleteId,
        if (eventName != null && eventName.isNotEmpty) 'event_name': eventName,
        if (weightClass != null && weightClass.isNotEmpty) 'weight_class': weightClass,
        if (dateFrom != null) 'date_from': dateFrom.toIso8601String().split('T').first,
        if (dateTo != null) 'date_to': dateTo.toIso8601String().split('T').first,
      }),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return decodeStatsList(response.body)
        .map(MatchEntry.fromMap)
        .toList(growable: false);
  }

  Future<List<MatchEntry>> fetchAthleteMatches({
    required int athleteId,
    required int teamId,
  }) async {
    final response = await _client.get(
      _uri('/api/v1/matches/athlete/$athleteId', {'team_id': teamId}),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return decodeStatsList(response.body)
        .map(MatchEntry.fromMap)
        .toList(growable: false);
  }

  void _throwIfNeeded(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    String message = 'Stats service request failed.';
    try {
      final json = decodeStatsObject(response.body);
      message = json['detail']?.toString() ?? message;
    } catch (_) {
      message = response.body.isNotEmpty ? response.body : message;
    }
    throw StatsApiException(message, response.statusCode);
  }
}

class StatsApiException implements Exception {
  const StatsApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => 'StatsApiException($statusCode): $message';
}
