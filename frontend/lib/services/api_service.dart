import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/messaging_models.dart';
import '../models/ai_replay_models.dart';
import '../models/team_model.dart';
import '../models/tournament_models.dart';
import '../models/user_profile.dart';
import '../models/weight_models.dart';

class ApiService {
  ApiService({required this.baseUrl});

  final String baseUrl;
  static const Duration _requestTimeout = Duration(seconds: 12);
  static const Duration _analysisTimeout = Duration(seconds: 120);

  Exception _networkException(Object error) {
    if (error is http.ClientException) {
      if (kIsWeb &&
          Uri.base.scheme == 'https' &&
          baseUrl.startsWith('http://')) {
        return Exception(
          'The app is loaded over HTTPS but the API URL is HTTP ($baseUrl). '
          'Use an HTTPS API base URL or proxy the API through the same origin.',
        );
      }
      return Exception(
        'The browser blocked the request before it reached the server. '
        'Check the API URL ($baseUrl), CORS, and mixed-content settings.',
      );
    }
    if (error is SocketException) {
      return Exception(
        'Cannot reach the server at $baseUrl. Make sure the backend is running and reachable from the app.',
      );
    }
    if (error is HttpException) {
      return Exception('Network error: ${error.message}');
    }
    return Exception('Request failed. Please try again.');
  }

  Future<http.Response> _request(
    Future<http.Response> Function() run,
  ) async {
    try {
      return await run().timeout(_requestTimeout);
    } on SocketException catch (error) {
      throw _networkException(error);
    } on HttpException catch (error) {
      throw _networkException(error);
    } on http.ClientException catch (error) {
      throw _networkException(error);
    } on TimeoutException {
      throw Exception(
        'The server took too long to respond. Check that the backend is running.',
      );
    } on FormatException {
      throw Exception('The server returned a response the app could not read.');
    }
  }

  Future<http.Response> _get(
    Uri uri, {
    Map<String, String>? headers,
  }) {
    return _request(() => http.get(uri, headers: headers));
  }

  Future<http.Response> _post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _request(() => http.post(uri, headers: headers, body: body));
  }

  Future<http.Response> _put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _request(() => http.put(uri, headers: headers, body: body));
  }

  Future<http.Response> _patch(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _request(() => http.patch(uri, headers: headers, body: body));
  }

  Future<http.Response> _delete(
    Uri uri, {
    Map<String, String>? headers,
  }) {
    return _request(() => http.delete(uri, headers: headers));
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    late final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_requestTimeout);
    } on SocketException catch (error) {
      throw _networkException(error);
    } on HttpException catch (error) {
      throw _networkException(error);
    } on http.ClientException catch (error) {
      throw _networkException(error);
    } on TimeoutException {
      throw Exception(
          'The server took too long to respond. Check that the backend is running.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Login failed');
    }
    return data['access_token'] as String;
  }

  Future<UserProfile> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    late final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'full_name': fullName,
              'email': email,
              'password': password,
              'role': role,
              'phone': phone,
            }),
          )
          .timeout(_requestTimeout);
    } on SocketException catch (error) {
      throw _networkException(error);
    } on HttpException catch (error) {
      throw _networkException(error);
    } on http.ClientException catch (error) {
      throw _networkException(error);
    } on TimeoutException {
      throw Exception(
          'The server took too long to respond. Check that the backend is running.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Register failed');
    }
    return UserProfile.fromJson(data);
  }

  Future<UserProfile> me(String token) async {
    final response = await _get(
      Uri.parse('$baseUrl/api/v1/users/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Profile failed');
    }
    return UserProfile.fromJson(data);
  }

  Future<UserProfile> updateProfile({
    required String token,
    required String fullName,
    String? phone,
  }) async {
    final response = await _put(
      Uri.parse('$baseUrl/api/v1/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'full_name': fullName,
        'phone': phone,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Profile update failed');
    }
    return UserProfile.fromJson(data);
  }

  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _put(
      Uri.parse('$baseUrl/api/v1/users/me/password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Password change failed');
    }
  }

  Future<List<TeamModel>> myTeams(String token) async {
    final response = await _get(
      Uri.parse('$baseUrl/api/v1/teams'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['detail'] ?? 'Teams failed');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => TeamModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TeamModel> createTeam({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/api/v1/teams'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Create team failed');
    }
    return TeamModel.fromJson(data);
  }

  Future<TeamModel> joinTeam({
    required String token,
    required String joinCode,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/api/v1/teams/join'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'join_code': joinCode}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Join team failed');
    }
    return TeamModel.fromJson(data);
  }

  Future<TeamModel> fetchTeamMembers({
    required String token,
    required int teamId,
  }) async {
    final response = await _get(
      Uri.parse('$baseUrl/api/v1/team-members/teams/$teamId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Load members failed');
    }
    return TeamModel.fromJson(data);
  }

  Future<TeamModel> updateBranding({
    required String token,
    required int teamId,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _put(
      Uri.parse('$baseUrl/api/v1/branding/teams/$teamId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Brand update failed');
    }
    return TeamModel.fromJson(data);
  }

  Future<TeamModel> updateMemberStatus({
    required String token,
    required int teamId,
    required int memberId,
    required String status,
  }) async {
    final response = await _put(
      Uri.parse('$baseUrl/api/v1/team-members/teams/$teamId/$memberId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Update member failed');
    }
    return TeamModel.fromJson(data);
  }

  Future<TeamModel> removeMember({
    required String token,
    required int teamId,
    required int memberId,
  }) async {
    final response = await _delete(
      Uri.parse('$baseUrl/api/v1/team-members/teams/$teamId/$memberId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Remove member failed');
    }
    return TeamModel.fromJson(data);
  }

  Future<String> rotateJoinCode({
    required String token,
    required int teamId,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/api/v1/teams/$teamId/rotate-join-code'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Rotate join code failed');
    }
    return data['join_code'] as String;
  }

  Future<TeamModel> uploadLogo({
    required String token,
    required int teamId,
    required File file,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/v1/uploads/teams/$teamId/logo'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    late final http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(_requestTimeout);
    } on SocketException catch (error) {
      throw _networkException(error);
    } on HttpException catch (error) {
      throw _networkException(error);
    } on http.ClientException catch (error) {
      throw _networkException(error);
    } on TimeoutException {
      throw Exception(
        'The server took too long to respond. Check that the backend is running.',
      );
    }
    final response = await http.Response.fromStream(streamed);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Logo upload failed');
    }
    return TeamModel.fromJson(data);
  }

  Future<AiReplayFilmStudyModel> analyzeReplayFilm({
    required String token,
    required String fileName,
    required List<int> bytes,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/v1/ai-replay/analyze-video'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ),
    );

    late final http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(_analysisTimeout);
    } on SocketException catch (error) {
      throw _networkException(error);
    } on HttpException catch (error) {
      throw _networkException(error);
    } on http.ClientException catch (error) {
      throw _networkException(error);
    } on TimeoutException {
      throw Exception(
        'Film study took too long. Try a shorter clip or check that the backend is running.',
      );
    }
    final response = await http.Response.fromStream(streamed);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Film study failed');
    }
    return AiReplayFilmStudyModel.fromJson(data);
  }

  Future<List<AnnouncementModel>> teamAnnouncements({
    required String token,
    required int teamId,
  }) async {
    final response = await _get(
      Uri.parse('$baseUrl/api/v1/announcements/team/$teamId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['detail'] ?? 'Announcements failed');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => AnnouncementModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TeamTextAlertReadinessModel> teamTextAlertReadiness({
    required String token,
    required int teamId,
  }) async {
    final response = await _get(
      Uri.parse(
          '$baseUrl/api/v1/announcements/team/$teamId/text-alert-readiness'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Text alert readiness failed');
    }
    return TeamTextAlertReadinessModel.fromJson(data);
  }

  Future<AnnouncementModel> sendAnnouncement({
    required String token,
    required int teamId,
    required String title,
    required String body,
    String audienceLabel = 'team',
    List<int>? recipientUserIds,
    bool sendTextAlert = false,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/api/v1/announcements/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'team_id': teamId,
        'title': title,
        'body': body,
        'audience_label': audienceLabel,
        'recipient_user_ids': recipientUserIds,
        'send_text_alert': sendTextAlert,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Announcement failed');
    }
    return AnnouncementModel.fromJson(data);
  }

  Future<List<MessageThreadSummaryModel>> userThreads({
    required String token,
    required int userId,
  }) async {
    final response = await _get(
      Uri.parse('$baseUrl/api/v1/messages/user/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['detail'] ?? 'Threads failed');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) =>
            MessageThreadSummaryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<MessageThreadDetailModel> createThread({
    required String token,
    required int teamId,
    required String title,
    required String threadType,
    required List<int> participantUserIds,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/api/v1/messages/thread/create'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'team_id': teamId,
        'title': title,
        'thread_type': threadType,
        'participant_user_ids': participantUserIds,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Thread creation failed');
    }
    return MessageThreadDetailModel.fromJson(data);
  }

  Future<MessageThreadDetailModel> fetchThread({
    required String token,
    required int threadId,
  }) async {
    final response = await _get(
      Uri.parse('$baseUrl/api/v1/messages/thread/$threadId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Thread failed');
    }
    return MessageThreadDetailModel.fromJson(data);
  }

  Future<MessageModel> sendMessage({
    required String token,
    required int threadId,
    required String body,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/api/v1/messages/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'thread_id': threadId,
        'body': body,
        'message_type': 'text',
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Send failed');
    }
    return MessageModel.fromJson(data);
  }

  Future<List<ParentLinkModel>> teamParentLinks({
    required String token,
    required int teamId,
  }) async {
    final response = await _get(
      Uri.parse('$baseUrl/api/v1/messages/parent-links/team/$teamId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['detail'] ?? 'Parent links failed');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => ParentLinkModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<SafetyAlertModel>> teamSafetyAlerts({
    required String token,
    required int teamId,
  }) async {
    final response = await _get(
      Uri.parse('$baseUrl/api/v1/messages/safety-alerts/team/$teamId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['detail'] ?? 'Safety alerts failed');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => SafetyAlertModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SafetyAlertModel> acknowledgeSafetyAlert({
    required String token,
    required int alertId,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/api/v1/messages/safety-alerts/$alertId/acknowledge'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Acknowledge failed');
    }
    return SafetyAlertModel.fromJson(data['alert'] as Map<String, dynamic>);
  }

  Future<WeightLogModel> logWeight({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/api/v1/weights/log'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Weight log failed');
    }
    return WeightLogModel.fromJson(data);
  }

  Future<List<WeightLogModel>> fetchWeightHistory({
    required String token,
    required int athleteId,
    required int teamId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/weights/history/$athleteId').replace(
      queryParameters: {'team_id': '$teamId'},
    );
    final response = await _get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['detail'] ?? 'Weight history failed');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => WeightLogModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<WeightPlanModel> calculateWeightPlan({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/api/v1/weights/plan/calculate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Weight plan failed');
    }
    return WeightPlanModel.fromJson(data);
  }

  Future<WeightPlanBundleModel> fetchWeightPlan({
    required String token,
    required int athleteId,
    required int teamId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/weights/plan/$athleteId').replace(
      queryParameters: {'team_id': '$teamId'},
    );
    final response = await _get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Weight plan lookup failed');
    }
    return WeightPlanBundleModel.fromJson(data);
  }

  Future<List<TeamWeightSnapshotModel>> fetchTeamWeightDashboard({
    required String token,
    required int teamId,
    String? group,
    int? grade,
    String? weightClass,
  }) async {
    final query = <String, String>{};
    if (group != null && group.isNotEmpty) query['group'] = group;
    if (grade != null) query['grade'] = '$grade';
    if (weightClass != null && weightClass.isNotEmpty) {
      query['weight_class'] = weightClass;
    }
    final uri =
        Uri.parse('$baseUrl/api/v1/weights/team-dashboard/$teamId').replace(
      queryParameters: query.isEmpty ? null : query,
    );
    final response = await _get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['detail'] ?? 'Weight dashboard failed');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) =>
            TeamWeightSnapshotModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<WeightAlertModel>> fetchWeightAlerts({
    required String token,
    required int teamId,
  }) async {
    final response = await _get(
      Uri.parse('$baseUrl/api/v1/weights/alerts/$teamId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['detail'] ?? 'Weight alerts failed');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => WeightAlertModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<LinkedAthleteModel>> fetchLinkedAthletes({
    required String token,
  }) async {
    final response = await _get(
      Uri.parse('$baseUrl/api/v1/weights/linked-athletes'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['detail'] ?? 'Linked athletes failed');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map(
            (item) => LinkedAthleteModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TournamentDiscoverResponseModel> discoverTournaments({
    required String token,
    int? teamId,
    String? search,
    String? source,
  }) async {
    final queryParameters = <String, String>{};
    if (teamId != null) queryParameters['team_id'] = '$teamId';
    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }
    if (source != null && source.trim().isNotEmpty) {
      queryParameters['source'] = source.trim();
    }

    final uri = Uri.parse('$baseUrl/api/v1/tournaments/discover').replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    final response = await _get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Tournament discovery failed');
    }
    return TournamentDiscoverResponseModel.fromJson(data);
  }

  Future<Map<String, dynamic>> runLiveTournamentScan({
    required String token,
    required String sourceKey,
    String? search,
    String? state,
    String? division,
    String? style,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/api/v1/tournaments/scan-runs/live'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'source_key': sourceKey,
        'search': search,
        'state': state,
        'division': division,
        'style': style,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Live tournament scan failed');
    }
    return data;
  }

  Future<TournamentExternalModel> createManualTournament({
    required String token,
    required int teamId,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/api/v1/tournaments/manual'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        ...payload,
        'team_id': teamId,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Manual tournament create failed');
    }
    return TournamentExternalModel.fromJson(
      data['tournament'] as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> saveTournament({
    required String token,
    required int teamId,
    required int tournamentId,
    String? notes,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/api/v1/tournaments/save'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'team_id': teamId,
        'tournament_id': tournamentId,
        'notes': notes,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Saving tournament failed');
    }
    return data;
  }

  Future<Map<String, dynamic>> addTournamentToSchedule({
    required String token,
    required int teamId,
    required int tournamentId,
    required DateTime startsAt,
    required DateTime endsAt,
    String? titleOverride,
    String? descriptionOverride,
    String? locationOverride,
    String? notes,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/api/v1/tournaments/add-to-schedule'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'team_id': teamId,
        'tournament_id': tournamentId,
        'starts_at': startsAt.toIso8601String(),
        'ends_at': endsAt.toIso8601String(),
        'title_override': titleOverride,
        'description_override': descriptionOverride,
        'location_override': locationOverride,
        'notes': notes,
        'checklist': const <String>[],
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Add to schedule failed');
    }
    return data;
  }

  Future<List<TeamLookupModel>> searchTeams({
    required String token,
    required String query,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/teams/search').replace(
      queryParameters: {'query': query.trim()},
    );
    final response = await _get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['detail'] ?? 'Team search failed');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => TeamLookupModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ManagedTournamentModel> createManagedTournament({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/api/v1/tournaments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Tournament create failed');
    }
    return ManagedTournamentModel.fromJson(data);
  }

  Future<ManagedTournamentModel> addTeamToManagedTournament({
    required String token,
    required int tournamentId,
    required int teamId,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/api/v1/tournaments/managed/$tournamentId/teams'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'team_id': teamId}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Add team failed');
    }
    return ManagedTournamentModel.fromJson(data);
  }

  Future<TournamentDashboardModel> getManagedTournamentDashboard({
    required String token,
    required int tournamentId,
  }) async {
    final response = await _get(
      Uri.parse('$baseUrl/api/v1/tournaments/managed/$tournamentId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Tournament dashboard failed');
    }
    return TournamentDashboardModel.fromJson(data);
  }

  Future<List<ManagedTournamentModel>> listTeamTournaments({
    required String token,
    required int teamId,
  }) async {
    final response = await _get(
      Uri.parse('$baseUrl/api/v1/tournaments/team/$teamId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['detail'] ?? 'Managed tournaments failed');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) =>
            ManagedTournamentModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<TournamentMatModel>> listTournamentMats({
    required String token,
    required int tournamentId,
  }) async {
    final response = await _get(
      Uri.parse('$baseUrl/api/v1/tournaments/managed/$tournamentId/mats'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['detail'] ?? 'Tournament mats failed');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map(
            (item) => TournamentMatModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TournamentMatModel> createTournamentMat({
    required String token,
    required int tournamentId,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/api/v1/tournaments/managed/$tournamentId/mats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Create mat failed');
    }
    return TournamentMatModel.fromJson(data);
  }

  Future<List<TournamentDualMeetModel>> listTournamentDualMeets({
    required String token,
    required int tournamentId,
  }) async {
    final response = await _get(
      Uri.parse('$baseUrl/api/v1/tournaments/managed/$tournamentId/dual-meets'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['detail'] ?? 'Dual meet list failed');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) =>
            TournamentDualMeetModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TournamentDualMeetModel> createTournamentDualMeet({
    required String token,
    required int tournamentId,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/api/v1/tournaments/managed/$tournamentId/dual-meets'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Create dual meet failed');
    }
    return TournamentDualMeetModel.fromJson(data);
  }

  Future<TournamentDualBoutModel> createTournamentDualBout({
    required String token,
    required int dualMeetId,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/api/v1/dual-meets/$dualMeetId/bouts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Create dual bout failed');
    }
    return TournamentDualBoutModel.fromJson(data);
  }

  Future<TournamentDualBoutModel> updateTournamentDualBout({
    required String token,
    required int dualBoutId,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _patch(
      Uri.parse('$baseUrl/api/v1/dual-bouts/$dualBoutId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Update dual bout failed');
    }
    return TournamentDualBoutModel.fromJson(data);
  }

  Future<List<TournamentEntryModel>> listTournamentEntries({
    required String token,
    required int tournamentId,
  }) async {
    final response = await _get(
      Uri.parse('$baseUrl/api/v1/tournaments/$tournamentId/entries'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['detail'] ?? 'Tournament entries failed');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) =>
            TournamentEntryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TournamentEntryModel> createTournamentEntry({
    required String token,
    required int tournamentId,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/api/v1/tournaments/$tournamentId/entries'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Create tournament entry failed');
    }
    return TournamentEntryModel.fromJson(data);
  }

  Future<TournamentEntryModel> updateTournamentEntry({
    required String token,
    required int entryId,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _patch(
      Uri.parse('$baseUrl/api/v1/tournaments/entries/$entryId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Update tournament entry failed');
    }
    return TournamentEntryModel.fromJson(data);
  }

  Future<List<SeedScoreModel>> calculateTournamentSeeds({
    required String token,
    required int tournamentId,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/api/v1/seeding/calculate/$tournamentId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Seed calculation failed');
    }
    return (data['results'] as List<dynamic>? ?? const [])
        .map((item) => SeedScoreModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<SeedScoreModel>> getWeightClassSeeds({
    required String token,
    required int tournamentId,
    required String weightClass,
  }) async {
    final response = await _get(
      Uri.parse('$baseUrl/api/v1/seeding/$tournamentId/$weightClass'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['detail'] ?? 'Weight class seeds failed');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => SeedScoreModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TournamentBracketModel> generateTournamentBracket({
    required String token,
    required int tournamentId,
    required String weightClass,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/api/v1/brackets/generate/$tournamentId/$weightClass'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Bracket generation failed');
    }
    return TournamentBracketModel.fromJson(data);
  }

  Future<TournamentBracketModel> getTournamentBracket({
    required String token,
    required int tournamentId,
    required String weightClass,
  }) async {
    final response = await _get(
      Uri.parse('$baseUrl/api/v1/brackets/$tournamentId/$weightClass'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Bracket lookup failed');
    }
    return TournamentBracketModel.fromJson(data);
  }

  Future<TournamentBracketMatchModel> updateTournamentBracketMatch({
    required String token,
    required int matchId,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _patch(
      Uri.parse('$baseUrl/api/v1/brackets/matches/$matchId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['detail'] ?? 'Bracket match update failed');
    }
    return TournamentBracketMatchModel.fromJson(data);
  }
}
