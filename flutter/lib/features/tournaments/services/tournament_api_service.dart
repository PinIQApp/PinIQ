import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/tournament_models.dart';

class TournamentApiService {
  TournamentApiService({
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

  Future<TournamentDiscoveryBundle> fetchDiscovery({
    required TournamentFilterModel filters,
  }) async {
    final response = await _client.get(
      _uri('/api/v1/tournaments/discover', filters.toQuery()),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return TournamentDiscoveryBundle.fromMap(decodeTournamentObject(response.body));
  }

  Future<TournamentDetailModel> fetchTournamentDetail({
    required int tournamentId,
    int? teamId,
    double? originLatitude,
    double? originLongitude,
  }) async {
    final response = await _client.get(
      _uri('/api/v1/tournaments/$tournamentId', {
        if (teamId != null) 'team_id': teamId,
        if (originLatitude != null) 'origin_latitude': originLatitude,
        if (originLongitude != null) 'origin_longitude': originLongitude,
      }),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return TournamentDetailModel.fromMap(decodeTournamentObject(response.body));
  }

  Future<List<SavedTournamentModel>> fetchSavedTournaments({
    required int teamId,
  }) async {
    final response = await _client.get(
      _uri('/api/v1/tournaments/saved/$teamId'),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return decodeTournamentList(response.body)
        .map(SavedTournamentModel.fromMap)
        .toList(growable: false);
  }

  Future<SavedTournamentModel> saveTournament({
    required int teamId,
    required int tournamentId,
    String? notes,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/tournaments/save'),
      headers: _headers,
      body: jsonEncode({
        'team_id': teamId,
        'tournament_id': tournamentId,
        'notes': notes,
      }),
    );
    _throwIfNeeded(response);
    return SavedTournamentModel.fromMap(decodeTournamentObject(response.body));
  }

  Future<int> addTournamentToSchedule({
    required int teamId,
    required int tournamentId,
    DateTime? startsAt,
    DateTime? endsAt,
    String? notes,
    List<String> checklist = const [],
    String? busDepartureNote,
    String? weighInNote,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/tournaments/add-to-schedule'),
      headers: _headers,
      body: jsonEncode({
        'team_id': teamId,
        'tournament_id': tournamentId,
        if (startsAt != null) 'starts_at': startsAt.toUtc().toIso8601String(),
        if (endsAt != null) 'ends_at': endsAt.toUtc().toIso8601String(),
        if (notes != null) 'notes': notes,
        'checklist': checklist,
        if (busDepartureNote != null) 'bus_departure_note': busDepartureNote,
        if (weighInNote != null) 'weigh_in_note': weighInNote,
      }),
    );
    _throwIfNeeded(response);
    final map = decodeTournamentObject(response.body);
    return (map['schedule_event_id'] as num).toInt();
  }

  Future<TournamentDetailModel> createManualTournament({
    required int teamId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? locationName,
    String? city,
    String? state,
    List<String> ageDivisions = const [],
    List<String>? weightClasses,
    required String eventType,
    String? registrationLink,
    String? description,
    DateTime? deadline,
    String? cost,
    String? contactName,
    String? contactEmail,
    String? contactPhone,
    String? notes,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/tournaments/manual'),
      headers: _headers,
      body: jsonEncode({
        'team_id': teamId,
        'name': name,
        'start_date': startDate.toIso8601String().split('T').first,
        'end_date': endDate.toIso8601String().split('T').first,
        'location_name': locationName,
        'city': city,
        'state': state,
        'age_divisions': ageDivisions,
        'weight_classes': weightClasses,
        'event_type': eventType,
        'registration_link': registrationLink,
        'description': description,
        'deadline': deadline?.toIso8601String().split('T').first,
        'cost': cost,
        'contact_name': contactName,
        'contact_email': contactEmail,
        'contact_phone': contactPhone,
        'notes': notes,
      }),
    );
    _throwIfNeeded(response);
    return TournamentDetailModel.fromMap(decodeTournamentObject(response.body));
  }

  void _throwIfNeeded(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    String message = 'Tournament service request failed.';
    try {
      final json = decodeTournamentObject(response.body);
      message = json['detail']?.toString() ?? message;
    } catch (_) {
      message = response.body.isNotEmpty ? response.body : message;
    }
    throw TournamentApiException(message, response.statusCode);
  }
}

class TournamentApiException implements Exception {
  const TournamentApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => 'TournamentApiException($statusCode): $message';
}
