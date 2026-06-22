import 'dart:convert';

class TournamentSourceModel {
  const TournamentSourceModel({
    required this.id,
    required this.sourceKey,
    required this.displayName,
    required this.ingestionMode,
    required this.supportsScraping,
    required this.supportsApi,
    required this.isActive,
  });

  final int id;
  final String sourceKey;
  final String displayName;
  final String ingestionMode;
  final bool supportsScraping;
  final bool supportsApi;
  final bool isActive;

  factory TournamentSourceModel.fromMap(Map<String, dynamic> map) {
    return TournamentSourceModel(
      id: (map['id'] as num).toInt(),
      sourceKey: map['source_key'] as String,
      displayName: map['display_name'] as String,
      ingestionMode: map['ingestion_mode'] as String,
      supportsScraping: map['supports_scraping'] as bool? ?? false,
      supportsApi: map['supports_api'] as bool? ?? false,
      isActive: map['is_active'] as bool? ?? false,
    );
  }
}

class TournamentFilterModel {
  const TournamentFilterModel({
    this.teamId,
    this.search,
    this.source,
    this.startDate,
    this.endDate,
    this.state,
    this.city,
    this.ageGroup,
    this.weightClass,
    this.eventType,
    this.radiusMiles,
    this.originLatitude,
    this.originLongitude,
  });

  final int? teamId;
  final String? search;
  final String? source;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? state;
  final String? city;
  final String? ageGroup;
  final String? weightClass;
  final String? eventType;
  final int? radiusMiles;
  final double? originLatitude;
  final double? originLongitude;

  Map<String, dynamic> toQuery() {
    return {
      if (teamId != null) 'team_id': teamId,
      if (search != null && search!.isNotEmpty) 'search': search,
      if (source != null && source!.isNotEmpty) 'source': source,
      if (startDate != null) 'start_date': _dateOnly(startDate!),
      if (endDate != null) 'end_date': _dateOnly(endDate!),
      if (state != null && state!.isNotEmpty) 'state': state,
      if (city != null && city!.isNotEmpty) 'city': city,
      if (ageGroup != null && ageGroup!.isNotEmpty) 'age_group': ageGroup,
      if (weightClass != null && weightClass!.isNotEmpty) 'weight_class': weightClass,
      if (eventType != null && eventType!.isNotEmpty) 'event_type': eventType,
      if (radiusMiles != null) 'radius_miles': radiusMiles,
      if (originLatitude != null) 'origin_latitude': originLatitude,
      if (originLongitude != null) 'origin_longitude': originLongitude,
    };
  }

  TournamentFilterModel copyWith({
    int? teamId,
    String? search,
    String? source,
    DateTime? startDate,
    DateTime? endDate,
    String? state,
    String? city,
    String? ageGroup,
    String? weightClass,
    String? eventType,
    int? radiusMiles,
    double? originLatitude,
    double? originLongitude,
    bool clearSearch = false,
  }) {
    return TournamentFilterModel(
      teamId: teamId ?? this.teamId,
      search: clearSearch ? null : search ?? this.search,
      source: source ?? this.source,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      state: state ?? this.state,
      city: city ?? this.city,
      ageGroup: ageGroup ?? this.ageGroup,
      weightClass: weightClass ?? this.weightClass,
      eventType: eventType ?? this.eventType,
      radiusMiles: radiusMiles ?? this.radiusMiles,
      originLatitude: originLatitude ?? this.originLatitude,
      originLongitude: originLongitude ?? this.originLongitude,
    );
  }
}

class TournamentSummaryModel {
  const TournamentSummaryModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.locationName,
    this.city,
    this.state,
    required this.ageDivisions,
    this.weightClasses,
    required this.eventType,
    this.registrationLink,
    this.eventPageLink,
    required this.sourceLabel,
    this.contactName,
    this.contactEmail,
    this.contactPhone,
    this.description,
    this.deadline,
    this.cost,
    required this.ingestionStatus,
    required this.isSaved,
    required this.isOnTeamSchedule,
    this.distanceMiles,
    this.recommendationScore,
  });

  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String? locationName;
  final String? city;
  final String? state;
  final List<String> ageDivisions;
  final List<String>? weightClasses;
  final String eventType;
  final String? registrationLink;
  final String? eventPageLink;
  final String sourceLabel;
  final String? contactName;
  final String? contactEmail;
  final String? contactPhone;
  final String? description;
  final DateTime? deadline;
  final String? cost;
  final String ingestionStatus;
  final bool isSaved;
  final bool isOnTeamSchedule;
  final double? distanceMiles;
  final double? recommendationScore;

  String get dateLabel {
    final start = '${startDate.month}/${startDate.day}';
    final end = '${endDate.month}/${endDate.day}';
    return startDate == endDate ? start : '$start - $end';
  }

  String get locationLabel {
    final cityState = [city, state].whereType<String>().where((value) => value.isNotEmpty).join(', ');
    if (locationName != null && cityState.isNotEmpty) {
      return '$locationName • $cityState';
    }
    return locationName ?? cityState;
  }

  factory TournamentSummaryModel.fromMap(Map<String, dynamic> map) {
    return TournamentSummaryModel(
      id: (map['id'] as num).toInt(),
      name: map['name'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      locationName: map['location_name'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      ageDivisions: (map['age_divisions'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      weightClasses: (map['weight_classes'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList(growable: false),
      eventType: map['event_type'] as String,
      registrationLink: map['registration_link'] as String?,
      eventPageLink: map['event_page_link'] as String?,
      sourceLabel: map['source_label'] as String,
      contactName: map['contact_name'] as String?,
      contactEmail: map['contact_email'] as String?,
      contactPhone: map['contact_phone'] as String?,
      description: map['description'] as String?,
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline'] as String) : null,
      cost: map['cost'] as String?,
      ingestionStatus: map['ingestion_status'] as String,
      isSaved: map['is_saved'] as bool? ?? false,
      isOnTeamSchedule: map['is_on_team_schedule'] as bool? ?? false,
      distanceMiles: (map['distance_miles'] as num?)?.toDouble(),
      recommendationScore: (map['recommendation_score'] as num?)?.toDouble(),
    );
  }
}

class SavedTournamentModel {
  const SavedTournamentModel({
    required this.id,
    required this.teamId,
    required this.tournamentExternalId,
    required this.savedByUserId,
    this.notes,
    this.addedToScheduleAt,
    this.sharedToTeamAt,
    required this.tournament,
  });

  final int id;
  final int teamId;
  final int tournamentExternalId;
  final int savedByUserId;
  final String? notes;
  final DateTime? addedToScheduleAt;
  final DateTime? sharedToTeamAt;
  final TournamentSummaryModel tournament;

  factory SavedTournamentModel.fromMap(Map<String, dynamic> map) {
    return SavedTournamentModel(
      id: (map['id'] as num).toInt(),
      teamId: (map['team_id'] as num).toInt(),
      tournamentExternalId: (map['tournament_external_id'] as num).toInt(),
      savedByUserId: (map['saved_by_user_id'] as num).toInt(),
      notes: map['notes'] as String?,
      addedToScheduleAt: map['added_to_schedule_at'] != null
          ? DateTime.parse(map['added_to_schedule_at'] as String)
          : null,
      sharedToTeamAt: map['shared_to_team_at'] != null
          ? DateTime.parse(map['shared_to_team_at'] as String)
          : null,
      tournament: TournamentSummaryModel.fromMap(
        Map<String, dynamic>.from(map['tournament'] as Map),
      ),
    );
  }
}

class TournamentDetailModel {
  const TournamentDetailModel({
    required this.tournament,
    this.availableRegistrationLink,
    this.savedEntry,
    this.scheduleEventId,
    required this.relatedTeamIds,
    required this.shareContext,
  });

  final TournamentSummaryModel tournament;
  final String? availableRegistrationLink;
  final SavedTournamentModel? savedEntry;
  final int? scheduleEventId;
  final List<int> relatedTeamIds;
  final Map<String, dynamic> shareContext;

  factory TournamentDetailModel.fromMap(Map<String, dynamic> map) {
    return TournamentDetailModel(
      tournament: TournamentSummaryModel.fromMap(
        Map<String, dynamic>.from(map['tournament'] as Map),
      ),
      availableRegistrationLink: map['available_registration_link'] as String?,
      savedEntry: map['saved_entry'] != null
          ? SavedTournamentModel.fromMap(Map<String, dynamic>.from(map['saved_entry'] as Map))
          : null,
      scheduleEventId: (map['schedule_event_id'] as num?)?.toInt(),
      relatedTeamIds: (map['related_team_ids'] as List<dynamic>? ?? const [])
          .map((item) => (item as num).toInt())
          .toList(growable: false),
      shareContext: Map<String, dynamic>.from(map['share_context'] as Map? ?? const {}),
    );
  }
}

class TournamentDiscoveryBundle {
  const TournamentDiscoveryBundle({
    required this.tournaments,
    required this.recommended,
    required this.nearby,
    required this.upcomingWeekend,
    required this.availableSources,
  });

  final List<TournamentSummaryModel> tournaments;
  final List<TournamentSummaryModel> recommended;
  final List<TournamentSummaryModel> nearby;
  final List<TournamentSummaryModel> upcomingWeekend;
  final List<TournamentSourceModel> availableSources;

  factory TournamentDiscoveryBundle.fromMap(Map<String, dynamic> map) {
    List<TournamentSummaryModel> readList(String key) {
      return (map[key] as List<dynamic>? ?? const [])
          .map((item) => TournamentSummaryModel.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    }

    return TournamentDiscoveryBundle(
      tournaments: readList('tournaments'),
      recommended: readList('recommended'),
      nearby: readList('nearby'),
      upcomingWeekend: readList('upcoming_weekend'),
      availableSources: (map['available_sources'] as List<dynamic>? ?? const [])
          .map((item) => TournamentSourceModel.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false),
    );
  }
}

Map<String, dynamic> decodeTournamentObject(String source) {
  return Map<String, dynamic>.from(jsonDecode(source) as Map);
}

List<Map<String, dynamic>> decodeTournamentList(String source) {
  return (jsonDecode(source) as List<dynamic>)
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList(growable: false);
}

String _dateOnly(DateTime value) => value.toIso8601String().split('T').first;
