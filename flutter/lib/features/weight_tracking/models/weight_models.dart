import 'dart:convert';

enum WeightPlanStatus { green, yellow, red }

WeightPlanStatus weightPlanStatusFromString(String value) {
  switch (value) {
    case 'green':
      return WeightPlanStatus.green;
    case 'red':
      return WeightPlanStatus.red;
    case 'yellow':
    default:
      return WeightPlanStatus.yellow;
  }
}

class WeightLogEntry {
  const WeightLogEntry({
    required this.id,
    required this.athleteId,
    required this.teamId,
    required this.createdByUserId,
    required this.loggedAt,
    required this.weight,
    this.bodyFatPercentage,
    this.hydrationNote,
    this.comments,
    required this.createdAt,
  });

  final int id;
  final int athleteId;
  final int teamId;
  final int createdByUserId;
  final DateTime loggedAt;
  final double weight;
  final double? bodyFatPercentage;
  final String? hydrationNote;
  final String? comments;
  final DateTime createdAt;

  factory WeightLogEntry.fromMap(Map<String, dynamic> map) {
    return WeightLogEntry(
      id: map['id'] as int,
      athleteId: map['athlete_id'] as int,
      teamId: map['team_id'] as int,
      createdByUserId: map['created_by_user_id'] as int,
      loggedAt: DateTime.parse(map['logged_at'] as String),
      weight: (map['weight'] as num).toDouble(),
      bodyFatPercentage: (map['body_fat_percentage'] as num?)?.toDouble(),
      hydrationNote: map['hydration_note'] as String?,
      comments: map['comments'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class WeightAlertItem {
  const WeightAlertItem({
    required this.id,
    required this.athleteId,
    required this.teamId,
    this.planId,
    required this.alertType,
    required this.alertMessage,
    required this.status,
    required this.severity,
    required this.triggeredAt,
    this.resolvedAt,
  });

  final int id;
  final int athleteId;
  final int teamId;
  final int? planId;
  final String alertType;
  final String alertMessage;
  final String status;
  final WeightPlanStatus severity;
  final DateTime triggeredAt;
  final DateTime? resolvedAt;

  factory WeightAlertItem.fromMap(Map<String, dynamic> map) {
    return WeightAlertItem(
      id: map['id'] as int,
      athleteId: map['athlete_id'] as int,
      teamId: map['team_id'] as int,
      planId: map['plan_id'] as int?,
      alertType: map['alert_type'] as String,
      alertMessage: map['alert_message'] as String,
      status: map['status'] as String,
      severity: weightPlanStatusFromString(map['severity'] as String),
      triggeredAt: DateTime.parse(map['triggered_at'] as String),
      resolvedAt: map['resolved_at'] != null
          ? DateTime.parse(map['resolved_at'] as String)
          : null,
    );
  }
}

class WeightPlan {
  const WeightPlan({
    required this.id,
    required this.athleteId,
    required this.teamId,
    this.athleteTargetId,
    required this.calculatedAt,
    required this.currentWeight,
    this.bodyFatPercentage,
    required this.targetWeightClass,
    required this.targetDate,
    required this.weeklyAllowedLoss,
    required this.requiredWeeklyLoss,
    required this.projectedReachableWeight,
    required this.estimatedReachableClass,
    required this.projectedTargetDate,
    required this.status,
    this.warningMessage,
    required this.summary,
    required this.planDetails,
  });

  final int id;
  final int athleteId;
  final int teamId;
  final int? athleteTargetId;
  final DateTime calculatedAt;
  final double currentWeight;
  final double? bodyFatPercentage;
  final double targetWeightClass;
  final DateTime targetDate;
  final double weeklyAllowedLoss;
  final double requiredWeeklyLoss;
  final double projectedReachableWeight;
  final double estimatedReachableClass;
  final DateTime projectedTargetDate;
  final WeightPlanStatus status;
  final String? warningMessage;
  final String summary;
  final Map<String, dynamic> planDetails;

  factory WeightPlan.fromMap(Map<String, dynamic> map) {
    return WeightPlan(
      id: map['id'] as int,
      athleteId: map['athlete_id'] as int,
      teamId: map['team_id'] as int,
      athleteTargetId: map['athlete_target_id'] as int?,
      calculatedAt: DateTime.parse(map['calculated_at'] as String),
      currentWeight: (map['current_weight'] as num).toDouble(),
      bodyFatPercentage: (map['body_fat_percentage'] as num?)?.toDouble(),
      targetWeightClass: (map['target_weight_class'] as num).toDouble(),
      targetDate: DateTime.parse(map['target_date'] as String),
      weeklyAllowedLoss: (map['weekly_allowed_loss'] as num).toDouble(),
      requiredWeeklyLoss: (map['required_weekly_loss'] as num).toDouble(),
      projectedReachableWeight:
          (map['projected_reachable_weight'] as num).toDouble(),
      estimatedReachableClass:
          (map['estimated_reachable_class'] as num).toDouble(),
      projectedTargetDate: DateTime.parse(map['projected_target_date'] as String),
      status: weightPlanStatusFromString(map['status'] as String),
      warningMessage: map['warning_message'] as String?,
      summary: map['summary'] as String,
      planDetails: Map<String, dynamic>.from(
        (map['plan_details'] as Map?) ?? const {},
      ),
    );
  }
}

class WeightPlanBundle {
  const WeightPlanBundle({
    required this.athleteId,
    this.latestPlan,
    required this.recentLogs,
    required this.activeAlerts,
  });

  final int athleteId;
  final WeightPlan? latestPlan;
  final List<WeightLogEntry> recentLogs;
  final List<WeightAlertItem> activeAlerts;

  factory WeightPlanBundle.fromMap(Map<String, dynamic> map) {
    return WeightPlanBundle(
      athleteId: map['athlete_id'] as int,
      latestPlan: map['latest_plan'] != null
          ? WeightPlan.fromMap(Map<String, dynamic>.from(map['latest_plan']))
          : null,
      recentLogs: ((map['recent_logs'] as List?) ?? const [])
          .map((item) => WeightLogEntry.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      activeAlerts: ((map['active_alerts'] as List?) ?? const [])
          .map((item) => WeightAlertItem.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class AthleteWeightSnapshot {
  const AthleteWeightSnapshot({
    required this.athleteId,
    required this.athleteName,
    this.gradeLabel,
    this.teamGroup,
    this.currentWeight,
    this.latestLogAt,
    this.targetWeightClass,
    this.targetDate,
    this.projectedReachableWeight,
    this.projectedClass,
    this.weeklyAllowedLoss,
    this.requiredWeeklyLoss,
    required this.status,
    required this.statusSummary,
    this.warningMessage,
    required this.alerts,
  });

  final int athleteId;
  final String athleteName;
  final String? gradeLabel;
  final String? teamGroup;
  final double? currentWeight;
  final DateTime? latestLogAt;
  final double? targetWeightClass;
  final DateTime? targetDate;
  final double? projectedReachableWeight;
  final double? projectedClass;
  final double? weeklyAllowedLoss;
  final double? requiredWeeklyLoss;
  final WeightPlanStatus status;
  final String statusSummary;
  final String? warningMessage;
  final List<WeightAlertItem> alerts;

  factory AthleteWeightSnapshot.fromMap(Map<String, dynamic> map) {
    return AthleteWeightSnapshot(
      athleteId: map['athlete_id'] as int,
      athleteName: map['athlete_name'] as String,
      gradeLabel: map['grade_label'] as String?,
      teamGroup: map['team_group'] as String?,
      currentWeight: (map['current_weight'] as num?)?.toDouble(),
      latestLogAt: map['latest_log_at'] != null
          ? DateTime.parse(map['latest_log_at'] as String)
          : null,
      targetWeightClass: (map['target_weight_class'] as num?)?.toDouble(),
      targetDate: map['target_date'] != null
          ? DateTime.parse(map['target_date'] as String)
          : null,
      projectedReachableWeight:
          (map['projected_reachable_weight'] as num?)?.toDouble(),
      projectedClass: (map['projected_class'] as num?)?.toDouble(),
      weeklyAllowedLoss: (map['weekly_allowed_loss'] as num?)?.toDouble(),
      requiredWeeklyLoss: (map['required_weekly_loss'] as num?)?.toDouble(),
      status: weightPlanStatusFromString(map['status'] as String),
      statusSummary: map['status_summary'] as String,
      warningMessage: map['warning_message'] as String?,
      alerts: ((map['alerts'] as List?) ?? const [])
          .map((item) => WeightAlertItem.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class LinkedAthlete {
  const LinkedAthlete({
    required this.athleteId,
    required this.athleteName,
    required this.teamId,
    required this.relationshipLabel,
  });

  final int athleteId;
  final String athleteName;
  final int teamId;
  final String relationshipLabel;

  factory LinkedAthlete.fromMap(Map<String, dynamic> map) {
    return LinkedAthlete(
      athleteId: map['athlete_id'] as int,
      athleteName: map['athlete_name'] as String,
      teamId: map['team_id'] as int,
      relationshipLabel: map['relationship_label'] as String,
    );
  }
}

Map<String, dynamic> decodeObject(String body) =>
    Map<String, dynamic>.from(jsonDecode(body) as Map);

List<Map<String, dynamic>> decodeList(String body) => (jsonDecode(body) as List)
    .map((item) => Map<String, dynamic>.from(item as Map))
    .toList();
