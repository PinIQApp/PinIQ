import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/schedule_models.dart';

class ScheduleApiService {
  ScheduleApiService({
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

  Future<TeamScheduleBundle> fetchTeamSchedule({
    required int teamId,
    ScheduleEventType? eventType,
    DateTime? startsAfter,
    DateTime? endsBefore,
  }) async {
    final response = await _client.get(
      _uri('/api/v1/events/team/$teamId', {
        if (eventType != null) 'event_type': scheduleEventTypeToApi(eventType),
        if (startsAfter != null)
          'starts_after': startsAfter.toUtc().toIso8601String(),
        if (endsBefore != null)
          'ends_before': endsBefore.toUtc().toIso8601String(),
      }),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return TeamScheduleBundle.fromMap(decodeScheduleObject(response.body));
  }

  Future<ScheduleEventItem> createEvent({
    required int teamId,
    required String title,
    String? description,
    required ScheduleEventType eventType,
    required DateTime startsAt,
    required DateTime endsAt,
    String? location,
    String? notes,
    List<String> checklist = const [],
    String? busDepartureNote,
    String? weighInNote,
    int? practicePlanId,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/events'),
      headers: _headers,
      body: jsonEncode({
        'team_id': teamId,
        'title': title,
        'description': description,
        'event_type': scheduleEventTypeToApi(eventType),
        'starts_at': startsAt.toUtc().toIso8601String(),
        'ends_at': endsAt.toUtc().toIso8601String(),
        'location': location,
        'notes': notes,
        'checklist': checklist,
        'bus_departure_note': busDepartureNote,
        'weigh_in_note': weighInNote,
        'practice_plan_id': practicePlanId,
      }),
    );
    _throwIfNeeded(response);
    return ScheduleEventItem.fromMap(decodeScheduleObject(response.body));
  }

  Future<ScheduleEventItem> updateEvent({
    required int eventId,
    String? title,
    String? description,
    ScheduleEventType? eventType,
    DateTime? startsAt,
    DateTime? endsAt,
    String? location,
    String? notes,
    List<String>? checklist,
    String? busDepartureNote,
    String? weighInNote,
    bool? isCancelled,
  }) async {
    final response = await _client.patch(
      _uri('/api/v1/events/$eventId'),
      headers: _headers,
      body: jsonEncode({
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (eventType != null) 'event_type': scheduleEventTypeToApi(eventType),
        if (startsAt != null) 'starts_at': startsAt.toUtc().toIso8601String(),
        if (endsAt != null) 'ends_at': endsAt.toUtc().toIso8601String(),
        if (location != null) 'location': location,
        if (notes != null) 'notes': notes,
        if (checklist != null) 'checklist': checklist,
        if (busDepartureNote != null) 'bus_departure_note': busDepartureNote,
        if (weighInNote != null) 'weigh_in_note': weighInNote,
        if (isCancelled != null) 'is_cancelled': isCancelled,
      }),
    );
    _throwIfNeeded(response);
    return ScheduleEventItem.fromMap(decodeScheduleObject(response.body));
  }

  Future<PracticePlanItem> createPractice({
    required int teamId,
    required String title,
    String? description,
    String? focus,
    DateTime? practiceDate,
    String? notes,
    int? templateId,
    required List<PracticeBlockItem> blocks,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/practices'),
      headers: _headers,
      body: jsonEncode({
        'team_id': teamId,
        'title': title,
        'description': description,
        'focus': focus,
        'practice_date': practiceDate?.toIso8601String().split('T').first,
        'notes': notes,
        'template_id': templateId,
        'blocks': blocks.map((block) => block.toCreateMap()).toList(),
      }),
    );
    _throwIfNeeded(response);
    return PracticePlanItem.fromMap(decodeScheduleObject(response.body));
  }

  Future<List<PracticePlanSummaryItem>> fetchTeamPractices({
    required int teamId,
  }) async {
    final response = await _client.get(
      _uri('/api/v1/practices/team/$teamId'),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return decodeScheduleList(
      response.body,
    ).map(PracticePlanSummaryItem.fromMap).toList(growable: false);
  }

  Future<PracticePlanItem> fetchPractice({required int practiceId}) async {
    final response = await _client.get(
      _uri('/api/v1/practices/$practiceId'),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return PracticePlanItem.fromMap(decodeScheduleObject(response.body));
  }

  Future<PracticePlanItem> updatePractice({
    required int practiceId,
    String? title,
    String? description,
    String? focus,
    DateTime? practiceDate,
    String? notes,
    int? templateId,
    List<PracticeBlockItem>? blocks,
  }) async {
    final response = await _client.patch(
      _uri('/api/v1/practices/$practiceId'),
      headers: _headers,
      body: jsonEncode({
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (focus != null) 'focus': focus,
        if (practiceDate != null)
          'practice_date': practiceDate.toIso8601String().split('T').first,
        if (notes != null) 'notes': notes,
        if (templateId != null) 'template_id': templateId,
        if (blocks != null)
          'blocks': blocks.map((block) => block.toCreateMap()).toList(),
      }),
    );
    _throwIfNeeded(response);
    return PracticePlanItem.fromMap(decodeScheduleObject(response.body));
  }

  Future<PracticePlanItem> duplicatePractice({
    required int practiceId,
    DateTime? practiceDate,
    String? title,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/practices/$practiceId/duplicate'),
      headers: _headers,
      body: jsonEncode({
        'practice_date': practiceDate?.toIso8601String().split('T').first,
        'title': title,
      }),
    );
    _throwIfNeeded(response);
    return PracticePlanItem.fromMap(decodeScheduleObject(response.body));
  }

  Future<PracticeAssignmentResult> assignPracticeToDate({
    required int practiceId,
    required DateTime targetDate,
    required DateTime startsAt,
    required DateTime endsAt,
    String? location,
    String? notes,
    List<String> checklist = const [],
    String? busDepartureNote,
    String? weighInNote,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/practices/$practiceId/assign-to-date'),
      headers: _headers,
      body: jsonEncode({
        'target_date': targetDate.toIso8601String().split('T').first,
        'starts_at': startsAt.toUtc().toIso8601String(),
        'ends_at': endsAt.toUtc().toIso8601String(),
        'location': location,
        'notes': notes,
        'checklist': checklist,
        'bus_departure_note': busDepartureNote,
        'weigh_in_note': weighInNote,
      }),
    );
    _throwIfNeeded(response);
    return PracticeAssignmentResult.fromMap(
      decodeScheduleObject(response.body),
    );
  }

  Future<PracticeTemplateItem> createTemplate({
    required int teamId,
    required String templateName,
    String? description,
    String? focus,
    required List<PracticeBlockItem> blocks,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/practice-templates'),
      headers: _headers,
      body: jsonEncode({
        'team_id': teamId,
        'template_name': templateName,
        'description': description,
        'focus': focus,
        'blocks': blocks.map((block) => block.toCreateMap()).toList(),
      }),
    );
    _throwIfNeeded(response);
    return PracticeTemplateItem.fromMap(decodeScheduleObject(response.body));
  }

  Future<List<PracticeTemplateItem>> fetchTeamTemplates({
    required int teamId,
  }) async {
    final response = await _client.get(
      _uri('/api/v1/practice-templates/team/$teamId'),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return decodeScheduleList(
      response.body,
    ).map(PracticeTemplateItem.fromMap).toList(growable: false);
  }

  void _throwIfNeeded(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    String message = 'Schedule service request failed.';
    try {
      final json = decodeScheduleObject(response.body);
      message = json['detail']?.toString() ?? message;
    } catch (_) {
      message = response.body.isNotEmpty ? response.body : message;
    }
    throw ScheduleApiException(message, response.statusCode);
  }
}

class ScheduleApiException implements Exception {
  const ScheduleApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => 'ScheduleApiException($statusCode): $message';
}
