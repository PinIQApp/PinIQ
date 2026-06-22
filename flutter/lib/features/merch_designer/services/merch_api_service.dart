import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/merch_models.dart';

class MerchApiService {
  MerchApiService({
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

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<List<MerchProduct>> fetchProducts() async {
    final response = await _client.get(
      _uri('/api/v1/merch/products'),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return decodeMerchList(response.body)
        .map((item) => MerchProduct.fromMap(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<MerchTemplate>> fetchTemplates() async {
    final response = await _client.get(
      _uri('/api/v1/merch/templates'),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return decodeMerchList(response.body)
        .map((item) => MerchTemplate.fromMap(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<MerchDesign>> fetchTeamDesigns({required int teamId}) async {
    final response = await _client.get(
      _uri('/api/v1/merch/designs/team/$teamId'),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return decodeMerchList(response.body)
        .map((item) => MerchDesign.fromMap(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<MerchDesign> fetchDesign({required int designId}) async {
    final response = await _client.get(
      _uri('/api/v1/merch/designs/$designId'),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return MerchDesign.fromMap(decodeMerchObject(response.body));
  }

  Future<MerchDesign> createDesign({
    required int teamId,
    required String productType,
    required String designName,
    String? templateKey,
    String? colorwayName,
    String? primaryColor,
    String? secondaryColor,
    String? accentColor,
    String? frontLogoUrl,
    String? backLogoUrl,
    String? frontText,
    String? backText,
    String? sleeveText,
    String? sponsorText,
    String? notes,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/merch/designs'),
      headers: _headers,
      body: jsonEncode({
        'team_id': teamId,
        'product_type': productType,
        'template_key': templateKey,
        'design_name': designName,
        'colorway_name': colorwayName,
        'primary_color': primaryColor,
        'secondary_color': secondaryColor,
        'accent_color': accentColor,
        'front_logo_url': frontLogoUrl,
        'back_logo_url': backLogoUrl,
        'front_text': frontText,
        'back_text': backText,
        'sleeve_text': sleeveText,
        'sponsor_text': sponsorText,
        'notes': notes,
      }),
    );
    _throwIfNeeded(response);
    return MerchDesign.fromMap(decodeMerchObject(response.body));
  }

  Future<MerchDesign> updateDesign({
    required int designId,
    String? designName,
    String? templateKey,
    String? colorwayName,
    String? primaryColor,
    String? secondaryColor,
    String? accentColor,
    String? frontLogoUrl,
    String? backLogoUrl,
    String? frontText,
    String? backText,
    String? sleeveText,
    String? sponsorText,
    String? notes,
  }) async {
    final response = await _client.patch(
      _uri('/api/v1/merch/designs/$designId'),
      headers: _headers,
      body: jsonEncode({
        'design_name': designName,
        'template_key': templateKey,
        'colorway_name': colorwayName,
        'primary_color': primaryColor,
        'secondary_color': secondaryColor,
        'accent_color': accentColor,
        'front_logo_url': frontLogoUrl,
        'back_logo_url': backLogoUrl,
        'front_text': frontText,
        'back_text': backText,
        'sleeve_text': sleeveText,
        'sponsor_text': sponsorText,
        'notes': notes,
      }),
    );
    _throwIfNeeded(response);
    return MerchDesign.fromMap(decodeMerchObject(response.body));
  }

  Future<MerchPublishResult> publishDesign({required int designId}) async {
    final response = await _client.post(
      _uri('/api/v1/merch/designs/$designId/publish'),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return MerchPublishResult.fromMap(decodeMerchObject(response.body));
  }

  Future<MerchDesign> exportDesign({
    required int designId,
    required String exportType,
    String? notes,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/merch/designs/$designId/export'),
      headers: _headers,
      body: jsonEncode({'export_type': exportType, 'notes': notes}),
    );
    _throwIfNeeded(response);
    return MerchDesign.fromMap(decodeMerchObject(response.body));
  }

  void _throwIfNeeded(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    String message = 'Merch designer request failed.';
    try {
      final json = decodeMerchObject(response.body);
      message = json['detail']?.toString() ?? message;
    } catch (_) {
      message = response.body.isNotEmpty ? response.body : message;
    }
    throw Exception(message);
  }
}
