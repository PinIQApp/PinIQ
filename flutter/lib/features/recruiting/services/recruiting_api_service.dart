import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/recruiting_models.dart';

class RecruitingApiService {
  RecruitingApiService({
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

  Future<List<RecruitingAthleteCard>> fetchAthletes({
    bool featuredOnly = false,
    bool openOnly = false,
    String sortBy = 'updated',
    int limit = 50,
  }) async {
    final response = await _client.get(
      _uri('/api/v1/recruiting/athletes', {
        'featured_only': featuredOnly,
        'open_only': openOnly,
        'sort_by': sortBy,
        'limit': limit,
      }),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return decodeRecruitingList(response.body)
        .map(RecruitingAthleteCard.fromMap)
        .toList(growable: false);
  }

  Future<RecruitingProfileDetail> fetchAthleteProfile(int athleteId) async {
    final response = await _client.get(
      _uri('/api/v1/recruiting/athlete/$athleteId'),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return RecruitingProfileDetail.fromMap(decodeRecruitingObject(response.body));
  }

  Future<RecruitingBoard> fetchBoard() async {
    final response = await _client.get(
      _uri('/api/v1/recruiting/board'),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return RecruitingBoard.fromMap(decodeRecruitingObject(response.body));
  }

  Future<RecruitingTrendingBundle> fetchTrending({int limit = 10}) async {
    final response = await _client.get(
      _uri('/api/v1/recruiting/trending', {'limit': limit}),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return RecruitingTrendingBundle.fromMap(decodeRecruitingObject(response.body));
  }

  Future<RecruitingSearchResponseModel> searchAthletes({
    String? weightClass,
    int? graduationYear,
    String? location,
    double? minWinPercentage,
    double? minBonusRate,
    double? minTakedownsPerMatch,
    bool? isOpen,
    bool? isActivelyLooking,
    String? query,
  }) async {
    final response = await _client.get(
      _uri('/api/v1/recruiting/search', {
        if (weightClass != null && weightClass.isNotEmpty) 'weight_class': weightClass,
        if (graduationYear != null) 'graduation_year': graduationYear,
        if (location != null && location.isNotEmpty) 'location': location,
        if (minWinPercentage != null) 'min_win_percentage': minWinPercentage,
        if (minBonusRate != null) 'min_bonus_rate': minBonusRate,
        if (minTakedownsPerMatch != null) 'min_takedowns_per_match': minTakedownsPerMatch,
        if (isOpen != null) 'is_open': isOpen,
        if (isActivelyLooking != null) 'is_actively_looking': isActivelyLooking,
        if (query != null && query.isNotEmpty) 'query': query,
      }),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return RecruitingSearchResponseModel.fromMap(decodeRecruitingObject(response.body));
  }

  Future<RecruitingProfileDetail> createProfile(RecruitingProfileDraft draft) async {
    final response = await _client.post(
      _uri('/api/v1/recruiting/profile'),
      headers: _headers,
      body: jsonEncode(draft.toJson()),
    );
    _throwIfNeeded(response);
    final json = decodeRecruitingObject(response.body);
    return RecruitingProfileDetail.fromMap(Map<String, dynamic>.from(json['profile'] as Map));
  }

  Future<RecruitingProfileDetail> updateProfile({
    required int athleteId,
    required RecruitingProfileDraft draft,
  }) async {
    final response = await _client.patch(
      _uri('/api/v1/recruiting/profile/$athleteId'),
      headers: _headers,
      body: jsonEncode(draft.toJson()),
    );
    _throwIfNeeded(response);
    final json = decodeRecruitingObject(response.body);
    return RecruitingProfileDetail.fromMap(Map<String, dynamic>.from(json['profile'] as Map));
  }

  Future<void> saveWatchlist({
    required int coachId,
    required int athleteId,
    List<String> tagLabels = const [],
  }) async {
    final response = await _client.post(
      _uri('/api/v1/recruiting/watchlist'),
      headers: _headers,
      body: jsonEncode({
        'coach_id': coachId,
        'athlete_id': athleteId,
        'tag_labels': tagLabels,
      }),
    );
    _throwIfNeeded(response);
  }

  Future<List<RecruitingWatchlistEntry>> fetchWatchlist(int coachId) async {
    final response = await _client.get(
      _uri('/api/v1/recruiting/watchlist/$coachId'),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return decodeRecruitingList(response.body)
        .map(RecruitingWatchlistEntry.fromMap)
        .toList(growable: false);
  }

  Future<void> saveNote({
    required int coachId,
    required int athleteId,
    required String note,
    List<String> tagLabels = const [],
  }) async {
    final response = await _client.post(
      _uri('/api/v1/recruiting/notes'),
      headers: _headers,
      body: jsonEncode({
        'coach_id': coachId,
        'athlete_id': athleteId,
        'note': note,
        'tag_labels': tagLabels,
      }),
    );
    _throwIfNeeded(response);
  }

  void _throwIfNeeded(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    String message = 'Recruiting service request failed.';
    try {
      final json = decodeRecruitingObject(response.body);
      message = json['detail']?.toString() ?? message;
    } catch (_) {
      message = response.body.isNotEmpty ? response.body : message;
    }
    throw RecruitingApiException(message, response.statusCode);
  }
}

class RecruitingApiException implements Exception {
  const RecruitingApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => 'RecruitingApiException($statusCode): $message';
}
