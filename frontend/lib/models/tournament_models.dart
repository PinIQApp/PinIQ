class TournamentSourceModel {
  const TournamentSourceModel({
    required this.id,
    required this.sourceKey,
    required this.displayName,
    required this.ingestionMode,
    required this.supportsScraping,
    required this.supportsApi,
    required this.isActive,
    this.baseUrl,
    this.notes,
  });

  final int id;
  final String sourceKey;
  final String displayName;
  final String ingestionMode;
  final bool supportsScraping;
  final bool supportsApi;
  final bool isActive;
  final String? baseUrl;
  final String? notes;

  factory TournamentSourceModel.fromJson(Map<String, dynamic> json) {
    return TournamentSourceModel(
      id: json['id'] as int,
      sourceKey: json['source_key'] as String,
      displayName: json['display_name'] as String,
      ingestionMode: json['ingestion_mode'] as String,
      supportsScraping: json['supports_scraping'] as bool? ?? false,
      supportsApi: json['supports_api'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      baseUrl: json['base_url'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

class TournamentExternalModel {
  const TournamentExternalModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.eventType,
    required this.sourceLabel,
    required this.ingestionStatus,
    required this.ageDivisions,
    required this.isSaved,
    required this.isOnTeamSchedule,
    this.locationName,
    this.city,
    this.state,
    this.weightClasses,
    this.registrationLink,
    this.eventPageLink,
    this.description,
    this.deadline,
    this.cost,
    this.distanceMiles,
    this.recommendationScore,
    this.ingestionNotes,
  });

  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String eventType;
  final String sourceLabel;
  final String ingestionStatus;
  final List<String> ageDivisions;
  final bool isSaved;
  final bool isOnTeamSchedule;
  final String? locationName;
  final String? city;
  final String? state;
  final List<String>? weightClasses;
  final String? registrationLink;
  final String? eventPageLink;
  final String? description;
  final DateTime? deadline;
  final String? cost;
  final double? distanceMiles;
  final double? recommendationScore;
  final String? ingestionNotes;

  factory TournamentExternalModel.fromJson(Map<String, dynamic> json) {
    return TournamentExternalModel(
      id: json['id'] as int,
      name: json['name'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      eventType: json['event_type'] as String,
      sourceLabel: json['source_label'] as String? ?? 'Unknown',
      ingestionStatus: json['ingestion_status'] as String? ?? 'unknown',
      ageDivisions: (json['age_divisions'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      isSaved: json['is_saved'] as bool? ?? false,
      isOnTeamSchedule: json['is_on_team_schedule'] as bool? ?? false,
      locationName: json['location_name'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      weightClasses: (json['weight_classes'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList(),
      registrationLink: json['registration_link'] as String?,
      eventPageLink: json['event_page_link'] as String?,
      description: json['description'] as String?,
      deadline: json['deadline'] == null ? null : DateTime.parse(json['deadline'] as String),
      cost: json['cost'] as String?,
      distanceMiles: (json['distance_miles'] as num?)?.toDouble(),
      recommendationScore: (json['recommendation_score'] as num?)?.toDouble(),
      ingestionNotes: json['ingestion_notes'] as String?,
    );
  }
}

class TournamentDiscoverResponseModel {
  const TournamentDiscoverResponseModel({
    required this.tournaments,
    required this.recommended,
    required this.nearby,
    required this.upcomingWeekend,
    required this.availableSources,
  });

  final List<TournamentExternalModel> tournaments;
  final List<TournamentExternalModel> recommended;
  final List<TournamentExternalModel> nearby;
  final List<TournamentExternalModel> upcomingWeekend;
  final List<TournamentSourceModel> availableSources;

  factory TournamentDiscoverResponseModel.fromJson(Map<String, dynamic> json) {
    return TournamentDiscoverResponseModel(
      tournaments: (json['tournaments'] as List<dynamic>? ?? const [])
          .map((item) => TournamentExternalModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      recommended: (json['recommended'] as List<dynamic>? ?? const [])
          .map((item) => TournamentExternalModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      nearby: (json['nearby'] as List<dynamic>? ?? const [])
          .map((item) => TournamentExternalModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      upcomingWeekend: (json['upcoming_weekend'] as List<dynamic>? ?? const [])
          .map((item) => TournamentExternalModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      availableSources: (json['available_sources'] as List<dynamic>? ?? const [])
          .map((item) => TournamentSourceModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ManagedTournamentTeamModel {
  const ManagedTournamentTeamModel({
    required this.id,
    required this.tournamentId,
    required this.teamId,
    this.notes,
  });

  final int id;
  final int tournamentId;
  final int teamId;
  final String? notes;

  factory ManagedTournamentTeamModel.fromJson(Map<String, dynamic> json) {
    return ManagedTournamentTeamModel(
      id: json['id'] as int,
      tournamentId: json['tournament_id'] as int,
      teamId: json['team_id'] as int,
      notes: json['notes'] as String?,
    );
  }
}

class ManagedTournamentModel {
  const ManagedTournamentModel({
    required this.id,
    required this.name,
    required this.eventType,
    required this.formatType,
    required this.eliminationStyle,
    required this.bracketSize,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.isPublic,
    required this.teams,
    this.location,
    this.notes,
  });

  final int id;
  final String name;
  final String eventType;
  final String formatType;
  final String? eliminationStyle;
  final int? bracketSize;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final bool isPublic;
  final String? location;
  final String? notes;
  final List<ManagedTournamentTeamModel> teams;

  factory ManagedTournamentModel.fromJson(Map<String, dynamic> json) {
    return ManagedTournamentModel(
      id: json['id'] as int,
      name: json['name'] as String,
      eventType: json['event_type'] as String,
      formatType: json['format_type'] as String? ?? 'single_elimination',
      eliminationStyle: json['elimination_style'] as String?,
      bracketSize: json['bracket_size'] as int?,
      status: json['status'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      isPublic: json['is_public'] as bool? ?? false,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      teams: (json['teams'] as List<dynamic>? ?? const [])
          .map((item) => ManagedTournamentTeamModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TournamentMatModel {
  const TournamentMatModel({
    required this.id,
    required this.tournamentId,
    required this.label,
    required this.status,
    required this.isActive,
    this.areaName,
    this.displayOrder,
  });

  final int id;
  final int tournamentId;
  final String label;
  final String status;
  final bool isActive;
  final String? areaName;
  final int? displayOrder;

  factory TournamentMatModel.fromJson(Map<String, dynamic> json) {
    return TournamentMatModel(
      id: json['id'] as int,
      tournamentId: json['tournament_id'] as int,
      label: json['label'] as String,
      status: json['status'] as String,
      isActive: json['is_active'] as bool? ?? true,
      areaName: json['area_name'] as String?,
      displayOrder: json['display_order'] as int?,
    );
  }
}

class TournamentDualBoutModel {
  const TournamentDualBoutModel({
    required this.id,
    required this.dualMeetId,
    required this.weightClass,
    required this.teamAPointsAwarded,
    required this.teamBPointsAwarded,
    required this.isComplete,
    this.boutOrder,
    this.wrestlerAName,
    this.wrestlerBName,
    this.winnerTeamId,
    this.resultType,
    this.resultSummary,
  });

  final int id;
  final int dualMeetId;
  final String weightClass;
  final int teamAPointsAwarded;
  final int teamBPointsAwarded;
  final bool isComplete;
  final int? boutOrder;
  final String? wrestlerAName;
  final String? wrestlerBName;
  final int? winnerTeamId;
  final String? resultType;
  final String? resultSummary;

  factory TournamentDualBoutModel.fromJson(Map<String, dynamic> json) {
    return TournamentDualBoutModel(
      id: json['id'] as int,
      dualMeetId: json['dual_meet_id'] as int,
      weightClass: json['weight_class'] as String,
      teamAPointsAwarded: json['team_a_points_awarded'] as int? ?? 0,
      teamBPointsAwarded: json['team_b_points_awarded'] as int? ?? 0,
      isComplete: json['is_complete'] as bool? ?? false,
      boutOrder: json['bout_order'] as int?,
      wrestlerAName: json['wrestler_a_name'] as String?,
      wrestlerBName: json['wrestler_b_name'] as String?,
      winnerTeamId: json['winner_team_id'] as int?,
      resultType: json['result_type'] as String?,
      resultSummary: json['result_summary'] as String?,
    );
  }
}

class TournamentEntryModel {
  const TournamentEntryModel({
    required this.id,
    required this.tournamentId,
    required this.teamId,
    required this.athleteId,
    required this.divisionName,
    required this.weightClass,
    required this.entryStatus,
    this.notes,
  });

  final int id;
  final int tournamentId;
  final int teamId;
  final int athleteId;
  final String divisionName;
  final String weightClass;
  final String entryStatus;
  final String? notes;

  factory TournamentEntryModel.fromJson(Map<String, dynamic> json) {
    return TournamentEntryModel(
      id: json['id'] as int,
      tournamentId: json['tournament_id'] as int,
      teamId: json['team_id'] as int,
      athleteId: json['athlete_id'] as int,
      divisionName: json['division_name'] as String,
      weightClass: json['weight_class'] as String,
      entryStatus: json['entry_status'] as String,
      notes: json['notes'] as String?,
    );
  }
}

class TournamentEntryGroupModel {
  const TournamentEntryGroupModel({
    required this.weightClass,
    required this.entries,
  });

  final String weightClass;
  final List<TournamentEntryModel> entries;

  factory TournamentEntryGroupModel.fromJson(Map<String, dynamic> json) {
    return TournamentEntryGroupModel(
      weightClass: json['weight_class'] as String,
      entries: (json['entries'] as List<dynamic>? ?? const [])
          .map((item) => TournamentEntryModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SeedScoreModel {
  const SeedScoreModel({
    required this.entryId,
    required this.athleteId,
    required this.teamId,
    required this.weightClass,
    required this.seedNumber,
    required this.seedScore,
    required this.seedExplanation,
  });

  final int entryId;
  final int athleteId;
  final int teamId;
  final String weightClass;
  final int seedNumber;
  final double seedScore;
  final String seedExplanation;

  factory SeedScoreModel.fromJson(Map<String, dynamic> json) {
    return SeedScoreModel(
      entryId: json['entry_id'] as int,
      athleteId: json['athlete_id'] as int,
      teamId: json['team_id'] as int,
      weightClass: json['weight_class'] as String,
      seedNumber: json['seed_number'] as int,
      seedScore: (json['seed_score'] as num).toDouble(),
      seedExplanation: json['seed_explanation'] as String,
    );
  }
}

class TournamentBracketMatchModel {
  const TournamentBracketMatchModel({
    required this.id,
    required this.roundNumber,
    required this.matchupOrder,
    required this.matchStatus,
    this.wrestlerAEntryId,
    this.wrestlerBEntryId,
    this.winnerEntryId,
    this.scheduledAt,
    this.matLabel,
    this.resultSummary,
  });

  final int id;
  final int roundNumber;
  final int matchupOrder;
  final String matchStatus;
  final int? wrestlerAEntryId;
  final int? wrestlerBEntryId;
  final int? winnerEntryId;
  final DateTime? scheduledAt;
  final String? matLabel;
  final String? resultSummary;

  factory TournamentBracketMatchModel.fromJson(Map<String, dynamic> json) {
    return TournamentBracketMatchModel(
      id: json['id'] as int,
      roundNumber: json['round_number'] as int,
      matchupOrder: json['matchup_order'] as int,
      matchStatus: json['match_status'] as String,
      wrestlerAEntryId: json['wrestler_a_entry_id'] as int?,
      wrestlerBEntryId: json['wrestler_b_entry_id'] as int?,
      winnerEntryId: json['winner_entry_id'] as int?,
      scheduledAt: json['scheduled_at'] == null ? null : DateTime.parse(json['scheduled_at'] as String),
      matLabel: json['mat_label'] as String?,
      resultSummary: json['result_summary'] as String?,
    );
  }
}

class TournamentBracketModel {
  const TournamentBracketModel({
    required this.id,
    required this.weightClass,
    required this.bracketType,
    required this.bracketSize,
    required this.status,
    required this.previewPayload,
    required this.matches,
  });

  final int id;
  final String weightClass;
  final String bracketType;
  final int bracketSize;
  final String status;
  final Map<String, dynamic> previewPayload;
  final List<TournamentBracketMatchModel> matches;

  factory TournamentBracketModel.fromJson(Map<String, dynamic> json) {
    return TournamentBracketModel(
      id: json['id'] as int,
      weightClass: json['weight_class'] as String,
      bracketType: json['bracket_type'] as String,
      bracketSize: json['bracket_size'] as int,
      status: json['status'] as String,
      previewPayload: Map<String, dynamic>.from(json['preview_payload'] as Map? ?? const {}),
      matches: (json['matches'] as List<dynamic>? ?? const [])
          .map((item) => TournamentBracketMatchModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TournamentDashboardModel {
  const TournamentDashboardModel({
    required this.entriesByWeightClass,
    required this.seededWeightClasses,
    required this.bracketedWeightClasses,
    required this.canEdit,
    required this.canSeed,
    required this.canFinalize,
  });

  final List<TournamentEntryGroupModel> entriesByWeightClass;
  final List<String> seededWeightClasses;
  final List<String> bracketedWeightClasses;
  final bool canEdit;
  final bool canSeed;
  final bool canFinalize;

  factory TournamentDashboardModel.fromJson(Map<String, dynamic> json) {
    return TournamentDashboardModel(
      entriesByWeightClass: (json['entries_by_weight_class'] as List<dynamic>? ?? const [])
          .map((item) => TournamentEntryGroupModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      seededWeightClasses: (json['seeded_weight_classes'] as List<dynamic>? ?? const []).cast<String>(),
      bracketedWeightClasses: (json['bracketed_weight_classes'] as List<dynamic>? ?? const []).cast<String>(),
      canEdit: json['can_edit'] as bool? ?? false,
      canSeed: json['can_seed'] as bool? ?? false,
      canFinalize: json['can_finalize'] as bool? ?? false,
    );
  }
}

class TournamentDualMeetModel {
  const TournamentDualMeetModel({
    required this.id,
    required this.tournamentId,
    required this.teamAId,
    required this.teamBId,
    required this.teamAScore,
    required this.teamBScore,
    required this.status,
    required this.bouts,
    this.divisionName,
    this.roundLabel,
    this.poolName,
    this.queuePosition,
    this.matId,
    this.winnerTeamId,
  });

  final int id;
  final int tournamentId;
  final int teamAId;
  final int teamBId;
  final int teamAScore;
  final int teamBScore;
  final String status;
  final List<TournamentDualBoutModel> bouts;
  final String? divisionName;
  final String? roundLabel;
  final String? poolName;
  final int? queuePosition;
  final int? matId;
  final int? winnerTeamId;

  factory TournamentDualMeetModel.fromJson(Map<String, dynamic> json) {
    return TournamentDualMeetModel(
      id: json['id'] as int,
      tournamentId: json['tournament_id'] as int,
      teamAId: json['team_a_id'] as int,
      teamBId: json['team_b_id'] as int,
      teamAScore: json['team_a_score'] as int? ?? 0,
      teamBScore: json['team_b_score'] as int? ?? 0,
      status: json['status'] as String,
      bouts: (json['bouts'] as List<dynamic>? ?? const [])
          .map((item) => TournamentDualBoutModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      divisionName: json['division_name'] as String?,
      roundLabel: json['round_label'] as String?,
      poolName: json['pool_name'] as String?,
      queuePosition: json['queue_position'] as int?,
      matId: json['mat_id'] as int?,
      winnerTeamId: json['winner_team_id'] as int?,
    );
  }
}
