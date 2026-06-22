import 'dart:convert';

enum MatchOutcome { win, loss }

enum MatchResultType {
  pin,
  techFall,
  majorDecision,
  decision,
  medicalForfeit,
  forfeit,
  defaultResult,
  disqualification,
}

MatchOutcome matchOutcomeFromString(String value) =>
    value == 'loss' ? MatchOutcome.loss : MatchOutcome.win;

String matchOutcomeToApi(MatchOutcome value) =>
    value == MatchOutcome.loss ? 'loss' : 'win';

MatchResultType matchResultTypeFromString(String value) {
  switch (value) {
    case 'tech_fall':
      return MatchResultType.techFall;
    case 'major_decision':
      return MatchResultType.majorDecision;
    case 'medical_forfeit':
      return MatchResultType.medicalForfeit;
    case 'forfeit':
      return MatchResultType.forfeit;
    case 'default':
      return MatchResultType.defaultResult;
    case 'disqualification':
      return MatchResultType.disqualification;
    case 'pin':
      return MatchResultType.pin;
    case 'decision':
    default:
      return MatchResultType.decision;
  }
}

String matchResultTypeToApi(MatchResultType value) {
  switch (value) {
    case MatchResultType.techFall:
      return 'tech_fall';
    case MatchResultType.majorDecision:
      return 'major_decision';
    case MatchResultType.medicalForfeit:
      return 'medical_forfeit';
    case MatchResultType.forfeit:
      return 'forfeit';
    case MatchResultType.defaultResult:
      return 'default';
    case MatchResultType.disqualification:
      return 'disqualification';
    case MatchResultType.pin:
      return 'pin';
    case MatchResultType.decision:
      return 'decision';
  }
}

String matchResultTypeLabel(MatchResultType value) {
  switch (value) {
    case MatchResultType.techFall:
      return 'Tech Fall';
    case MatchResultType.majorDecision:
      return 'Major Decision';
    case MatchResultType.medicalForfeit:
      return 'Medical Forfeit';
    case MatchResultType.forfeit:
      return 'Forfeit';
    case MatchResultType.defaultResult:
      return 'Default';
    case MatchResultType.disqualification:
      return 'Disqualification';
    case MatchResultType.pin:
      return 'Pin';
    case MatchResultType.decision:
      return 'Decision';
  }
}

class MatchStatLine {
  const MatchStatLine({
    required this.id,
    required this.matchId,
    required this.athleteId,
    required this.teamId,
    required this.takedowns,
    required this.escapes,
    required this.reversals,
    required this.nearfallPoints,
    required this.stallCalls,
    this.rideTimeSeconds,
    this.shotAttempts,
    this.shotConversions,
    required this.createdAt,
    required this.updatedAt,
    this.shotConversionRate,
  });

  final int id;
  final int matchId;
  final int athleteId;
  final int teamId;
  final int takedowns;
  final int escapes;
  final int reversals;
  final int nearfallPoints;
  final int stallCalls;
  final int? rideTimeSeconds;
  final int? shotAttempts;
  final int? shotConversions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? shotConversionRate;

  factory MatchStatLine.fromMap(Map<String, dynamic> map) {
    return MatchStatLine(
      id: map['id'] as int,
      matchId: map['match_id'] as int,
      athleteId: map['athlete_id'] as int,
      teamId: map['team_id'] as int,
      takedowns: (map['takedowns'] as num).toInt(),
      escapes: (map['escapes'] as num).toInt(),
      reversals: (map['reversals'] as num).toInt(),
      nearfallPoints: (map['nearfall_points'] as num).toInt(),
      stallCalls: (map['stall_calls'] as num).toInt(),
      rideTimeSeconds: (map['ride_time_seconds'] as num?)?.toInt(),
      shotAttempts: (map['shot_attempts'] as num?)?.toInt(),
      shotConversions: (map['shot_conversions'] as num?)?.toInt(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      shotConversionRate: (map['shot_conversion_rate'] as num?)?.toDouble(),
    );
  }
}

class MatchEntry {
  const MatchEntry({
    required this.id,
    required this.athleteId,
    required this.teamId,
    required this.createdByUserId,
    this.updatedByUserId,
    required this.opponentName,
    this.opponentSchool,
    this.eventName,
    required this.matchDate,
    required this.weightClass,
    required this.result,
    required this.resultType,
    required this.scoreFor,
    required this.scoreAgainst,
    required this.scoreDisplay,
    this.pinTime,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.stats,
  });

  final int id;
  final int athleteId;
  final int teamId;
  final int createdByUserId;
  final int? updatedByUserId;
  final String opponentName;
  final String? opponentSchool;
  final String? eventName;
  final DateTime matchDate;
  final String weightClass;
  final MatchOutcome result;
  final MatchResultType resultType;
  final int scoreFor;
  final int scoreAgainst;
  final String scoreDisplay;
  final String? pinTime;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MatchStatLine? stats;

  factory MatchEntry.fromMap(Map<String, dynamic> map) {
    return MatchEntry(
      id: map['id'] as int,
      athleteId: map['athlete_id'] as int,
      teamId: map['team_id'] as int,
      createdByUserId: map['created_by_user_id'] as int,
      updatedByUserId: map['updated_by_user_id'] as int?,
      opponentName: map['opponent_name'] as String,
      opponentSchool: map['opponent_school'] as String?,
      eventName: map['event_name'] as String?,
      matchDate: DateTime.parse(map['match_date'] as String),
      weightClass: map['weight_class'] as String,
      result: matchOutcomeFromString(map['result'] as String),
      resultType: matchResultTypeFromString(map['result_type'] as String),
      scoreFor: (map['score_for'] as num).toInt(),
      scoreAgainst: (map['score_against'] as num).toInt(),
      scoreDisplay: map['score_display'] as String,
      pinTime: map['pin_time'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      stats: map['stats'] != null
          ? MatchStatLine.fromMap(Map<String, dynamic>.from(map['stats']))
          : null,
    );
  }
}

class RecordSummaryModel {
  const RecordSummaryModel({
    required this.wins,
    required this.losses,
    required this.totalMatches,
    required this.winPercentage,
  });

  final int wins;
  final int losses;
  final int totalMatches;
  final double winPercentage;

  factory RecordSummaryModel.fromMap(Map<String, dynamic> map) {
    return RecordSummaryModel(
      wins: (map['wins'] as num).toInt(),
      losses: (map['losses'] as num).toInt(),
      totalMatches: (map['total_matches'] as num).toInt(),
      winPercentage: (map['win_percentage'] as num).toDouble(),
    );
  }
}

class ResultTypeBreakdownModel {
  const ResultTypeBreakdownModel({
    required this.pins,
    required this.techFalls,
    required this.majorDecisions,
    required this.decisions,
    required this.pinRate,
    required this.techFallRate,
    required this.majorDecisionRate,
    required this.decisionRate,
  });

  final int pins;
  final int techFalls;
  final int majorDecisions;
  final int decisions;
  final double pinRate;
  final double techFallRate;
  final double majorDecisionRate;
  final double decisionRate;

  factory ResultTypeBreakdownModel.fromMap(Map<String, dynamic> map) {
    return ResultTypeBreakdownModel(
      pins: (map['pins'] as num).toInt(),
      techFalls: (map['tech_falls'] as num).toInt(),
      majorDecisions: (map['major_decisions'] as num).toInt(),
      decisions: (map['decisions'] as num).toInt(),
      pinRate: (map['pin_rate'] as num).toDouble(),
      techFallRate: (map['tech_fall_rate'] as num).toDouble(),
      majorDecisionRate: (map['major_decision_rate'] as num).toDouble(),
      decisionRate: (map['decision_rate'] as num).toDouble(),
    );
  }
}

class TrendSummaryModel {
  const TrendSummaryModel({
    required this.lastFive,
    required this.trendLabel,
    required this.recentRecord,
  });

  final List<String> lastFive;
  final String trendLabel;
  final String recentRecord;

  factory TrendSummaryModel.fromMap(Map<String, dynamic> map) {
    return TrendSummaryModel(
      lastFive: ((map['last_five'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      trendLabel: map['trend_label'] as String,
      recentRecord: map['recent_record'] as String,
    );
  }
}

class StatAveragesModel {
  const StatAveragesModel({
    required this.takedownsPerMatch,
    required this.escapesPerMatch,
    required this.reversalsPerMatch,
    required this.nearfallPointsPerMatch,
    required this.stallCallsPerMatch,
    required this.rideTimeSecondsPerMatch,
    this.shotConversionRate,
  });

  final double takedownsPerMatch;
  final double escapesPerMatch;
  final double reversalsPerMatch;
  final double nearfallPointsPerMatch;
  final double stallCallsPerMatch;
  final double rideTimeSecondsPerMatch;
  final double? shotConversionRate;

  factory StatAveragesModel.fromMap(Map<String, dynamic> map) {
    return StatAveragesModel(
      takedownsPerMatch: (map['takedowns_per_match'] as num).toDouble(),
      escapesPerMatch: (map['escapes_per_match'] as num).toDouble(),
      reversalsPerMatch: (map['reversals_per_match'] as num).toDouble(),
      nearfallPointsPerMatch: (map['nearfall_points_per_match'] as num).toDouble(),
      stallCallsPerMatch: (map['stall_calls_per_match'] as num).toDouble(),
      rideTimeSecondsPerMatch: (map['ride_time_seconds_per_match'] as num).toDouble(),
      shotConversionRate: (map['shot_conversion_rate'] as num?)?.toDouble(),
    );
  }
}

class StrengthWeaknessSummaryModel {
  const StrengthWeaknessSummaryModel({
    required this.strengths,
    required this.weaknesses,
    required this.coachSummary,
  });

  final List<String> strengths;
  final List<String> weaknesses;
  final String coachSummary;

  factory StrengthWeaknessSummaryModel.fromMap(Map<String, dynamic> map) {
    return StrengthWeaknessSummaryModel(
      strengths: ((map['strengths'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      weaknesses: ((map['weaknesses'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      coachSummary: map['coach_summary'] as String,
    );
  }
}

class AthleteStatsDashboard {
  const AthleteStatsDashboard({
    required this.athleteId,
    required this.athleteName,
    required this.teamId,
    required this.record,
    required this.resultTypes,
    required this.bonusPointWins,
    required this.bonusPointRate,
    required this.recentTrend,
    required this.lastFiveMatches,
    required this.statAverages,
    required this.strengthsWeaknesses,
    required this.visibleAs,
    this.snapshotUpdatedAt,
  });

  final int athleteId;
  final String athleteName;
  final int teamId;
  final RecordSummaryModel record;
  final ResultTypeBreakdownModel resultTypes;
  final int bonusPointWins;
  final double bonusPointRate;
  final TrendSummaryModel recentTrend;
  final List<MatchEntry> lastFiveMatches;
  final StatAveragesModel statAverages;
  final StrengthWeaknessSummaryModel strengthsWeaknesses;
  final String visibleAs;
  final DateTime? snapshotUpdatedAt;

  factory AthleteStatsDashboard.fromMap(Map<String, dynamic> map) {
    return AthleteStatsDashboard(
      athleteId: map['athlete_id'] as int,
      athleteName: map['athlete_name'] as String,
      teamId: map['team_id'] as int,
      record: RecordSummaryModel.fromMap(Map<String, dynamic>.from(map['record'])),
      resultTypes: ResultTypeBreakdownModel.fromMap(
        Map<String, dynamic>.from(map['result_types']),
      ),
      bonusPointWins: (map['bonus_point_wins'] as num).toInt(),
      bonusPointRate: (map['bonus_point_rate'] as num).toDouble(),
      recentTrend: TrendSummaryModel.fromMap(
        Map<String, dynamic>.from(map['recent_trend']),
      ),
      lastFiveMatches: ((map['last_five_matches'] as List?) ?? const [])
          .map((item) => MatchEntry.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      statAverages: StatAveragesModel.fromMap(
        Map<String, dynamic>.from(map['stat_averages']),
      ),
      strengthsWeaknesses: StrengthWeaknessSummaryModel.fromMap(
        Map<String, dynamic>.from(map['strengths_weaknesses']),
      ),
      visibleAs: map['visible_as'] as String,
      snapshotUpdatedAt: map['snapshot_updated_at'] != null
          ? DateTime.parse(map['snapshot_updated_at'] as String)
          : null,
    );
  }
}

class LeaderEntryModel {
  const LeaderEntryModel({
    required this.athleteId,
    required this.athleteName,
    required this.metricLabel,
    required this.metricValue,
    this.subtitle,
  });

  final int athleteId;
  final String athleteName;
  final String metricLabel;
  final double metricValue;
  final String? subtitle;

  factory LeaderEntryModel.fromMap(Map<String, dynamic> map) {
    return LeaderEntryModel(
      athleteId: map['athlete_id'] as int,
      athleteName: map['athlete_name'] as String,
      metricLabel: map['metric_label'] as String,
      metricValue: (map['metric_value'] as num).toDouble(),
      subtitle: map['subtitle'] as String?,
    );
  }
}

class WeightClassBreakdownModel {
  const WeightClassBreakdownModel({
    required this.weightClass,
    required this.totalMatches,
    required this.wins,
    required this.losses,
    required this.winPercentage,
  });

  final String weightClass;
  final int totalMatches;
  final int wins;
  final int losses;
  final double winPercentage;

  factory WeightClassBreakdownModel.fromMap(Map<String, dynamic> map) {
    return WeightClassBreakdownModel(
      weightClass: map['weight_class'] as String,
      totalMatches: (map['total_matches'] as num).toInt(),
      wins: (map['wins'] as num).toInt(),
      losses: (map['losses'] as num).toInt(),
      winPercentage: (map['win_percentage'] as num).toDouble(),
    );
  }
}

class TeamStatsDashboard {
  const TeamStatsDashboard({
    required this.teamId,
    required this.teamName,
    required this.record,
    required this.bonusPointWins,
    required this.bonusPointRate,
    required this.totalPins,
    required this.recentTrend,
    required this.leaders,
    required this.weightClassBreakdown,
    required this.recentMatches,
    required this.visibleAs,
    this.snapshotUpdatedAt,
  });

  final int teamId;
  final String teamName;
  final RecordSummaryModel record;
  final int bonusPointWins;
  final double bonusPointRate;
  final int totalPins;
  final TrendSummaryModel recentTrend;
  final List<LeaderEntryModel> leaders;
  final List<WeightClassBreakdownModel> weightClassBreakdown;
  final List<MatchEntry> recentMatches;
  final String visibleAs;
  final DateTime? snapshotUpdatedAt;

  factory TeamStatsDashboard.fromMap(Map<String, dynamic> map) {
    return TeamStatsDashboard(
      teamId: map['team_id'] as int,
      teamName: map['team_name'] as String,
      record: RecordSummaryModel.fromMap(Map<String, dynamic>.from(map['record'])),
      bonusPointWins: (map['bonus_point_wins'] as num).toInt(),
      bonusPointRate: (map['bonus_point_rate'] as num).toDouble(),
      totalPins: (map['total_pins'] as num).toInt(),
      recentTrend: TrendSummaryModel.fromMap(
        Map<String, dynamic>.from(map['recent_trend']),
      ),
      leaders: ((map['leaders'] as List?) ?? const [])
          .map((item) => LeaderEntryModel.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      weightClassBreakdown: ((map['weight_class_breakdown'] as List?) ?? const [])
          .map(
            (item) => WeightClassBreakdownModel.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
      recentMatches: ((map['recent_matches'] as List?) ?? const [])
          .map((item) => MatchEntry.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      visibleAs: map['visible_as'] as String,
      snapshotUpdatedAt: map['snapshot_updated_at'] != null
          ? DateTime.parse(map['snapshot_updated_at'] as String)
          : null,
    );
  }
}

class TeamLeaders {
  const TeamLeaders({
    required this.teamId,
    required this.mostPins,
    required this.bestWinPercentage,
    required this.bonusPointLeaders,
  });

  final int teamId;
  final List<LeaderEntryModel> mostPins;
  final List<LeaderEntryModel> bestWinPercentage;
  final List<LeaderEntryModel> bonusPointLeaders;

  factory TeamLeaders.fromMap(Map<String, dynamic> map) {
    return TeamLeaders(
      teamId: map['team_id'] as int,
      mostPins: ((map['most_pins'] as List?) ?? const [])
          .map((item) => LeaderEntryModel.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      bestWinPercentage: ((map['best_win_percentage'] as List?) ?? const [])
          .map((item) => LeaderEntryModel.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      bonusPointLeaders: ((map['bonus_point_leaders'] as List?) ?? const [])
          .map((item) => LeaderEntryModel.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false),
    );
  }
}

class AthleteRecentBundle {
  const AthleteRecentBundle({
    required this.athleteId,
    required this.teamId,
    required this.trend,
    required this.matches,
  });

  final int athleteId;
  final int teamId;
  final TrendSummaryModel trend;
  final List<MatchEntry> matches;

  factory AthleteRecentBundle.fromMap(Map<String, dynamic> map) {
    return AthleteRecentBundle(
      athleteId: map['athlete_id'] as int,
      teamId: map['team_id'] as int,
      trend: TrendSummaryModel.fromMap(Map<String, dynamic>.from(map['trend'])),
      matches: ((map['matches'] as List?) ?? const [])
          .map((item) => MatchEntry.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false),
    );
  }
}

Map<String, dynamic> decodeStatsObject(String body) =>
    Map<String, dynamic>.from(jsonDecode(body) as Map);

List<Map<String, dynamic>> decodeStatsList(String body) => (jsonDecode(body) as List)
    .map((item) => Map<String, dynamic>.from(item as Map))
    .toList();
