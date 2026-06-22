class WeightLogModel {
  final int id;
  final int athleteId;
  final int teamId;
  final int createdByUserId;
  final DateTime loggedAt;
  final double weight;
  final double? bodyFatPercentage;
  final String? hydrationNote;
  final String? comments;

  WeightLogModel({
    required this.id,
    required this.athleteId,
    required this.teamId,
    required this.createdByUserId,
    required this.loggedAt,
    required this.weight,
    required this.bodyFatPercentage,
    required this.hydrationNote,
    required this.comments,
  });

  factory WeightLogModel.fromJson(Map<String, dynamic> json) {
    return WeightLogModel(
      id: json['id'] as int,
      athleteId: json['athlete_id'] as int,
      teamId: json['team_id'] as int,
      createdByUserId: json['created_by_user_id'] as int,
      loggedAt: DateTime.parse(json['logged_at'] as String),
      weight: (json['weight'] as num).toDouble(),
      bodyFatPercentage: (json['body_fat_percentage'] as num?)?.toDouble(),
      hydrationNote: json['hydration_note'] as String?,
      comments: json['comments'] as String?,
    );
  }
}

class WeightAlertModel {
  final int id;
  final int athleteId;
  final int teamId;
  final int? planId;
  final String alertType;
  final String alertMessage;
  final String status;
  final String severity;
  final DateTime triggeredAt;

  WeightAlertModel({
    required this.id,
    required this.athleteId,
    required this.teamId,
    required this.planId,
    required this.alertType,
    required this.alertMessage,
    required this.status,
    required this.severity,
    required this.triggeredAt,
  });

  factory WeightAlertModel.fromJson(Map<String, dynamic> json) {
    return WeightAlertModel(
      id: json['id'] as int,
      athleteId: json['athlete_id'] as int,
      teamId: json['team_id'] as int,
      planId: json['plan_id'] as int?,
      alertType: json['alert_type'] as String,
      alertMessage: json['alert_message'] as String,
      status: json['status'] as String,
      severity: json['severity'] as String,
      triggeredAt: DateTime.parse(json['triggered_at'] as String),
    );
  }
}

class WeightPlanModel {
  final int id;
  final int athleteId;
  final int teamId;
  final double currentWeight;
  final double? bodyFatPercentage;
  final double targetWeightClass;
  final DateTime calculatedAt;
  final DateTime targetDate;
  final double weeklyAllowedLoss;
  final double requiredWeeklyLoss;
  final double projectedReachableWeight;
  final double estimatedReachableClass;
  final DateTime projectedTargetDate;
  final String status;
  final String? warningMessage;
  final String summary;
  final Map<String, dynamic> planDetails;

  WeightPlanModel({
    required this.id,
    required this.athleteId,
    required this.teamId,
    required this.currentWeight,
    required this.bodyFatPercentage,
    required this.targetWeightClass,
    required this.calculatedAt,
    required this.targetDate,
    required this.weeklyAllowedLoss,
    required this.requiredWeeklyLoss,
    required this.projectedReachableWeight,
    required this.estimatedReachableClass,
    required this.projectedTargetDate,
    required this.status,
    required this.warningMessage,
    required this.summary,
    required this.planDetails,
  });

  factory WeightPlanModel.fromJson(Map<String, dynamic> json) {
    return WeightPlanModel(
      id: json['id'] as int,
      athleteId: json['athlete_id'] as int,
      teamId: json['team_id'] as int,
      currentWeight: (json['current_weight'] as num).toDouble(),
      bodyFatPercentage: (json['body_fat_percentage'] as num?)?.toDouble(),
      targetWeightClass: (json['target_weight_class'] as num).toDouble(),
      calculatedAt: DateTime.parse(json['calculated_at'] as String),
      targetDate: DateTime.parse(json['target_date'] as String),
      weeklyAllowedLoss: (json['weekly_allowed_loss'] as num).toDouble(),
      requiredWeeklyLoss: (json['required_weekly_loss'] as num).toDouble(),
      projectedReachableWeight: (json['projected_reachable_weight'] as num).toDouble(),
      estimatedReachableClass: (json['estimated_reachable_class'] as num).toDouble(),
      projectedTargetDate: DateTime.parse(json['projected_target_date'] as String),
      status: json['status'] as String,
      warningMessage: json['warning_message'] as String?,
      summary: json['summary'] as String,
      planDetails: (json['plan_details'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class WeightPlanBundleModel {
  final int athleteId;
  final WeightPlanModel? latestPlan;
  final List<WeightLogModel> recentLogs;
  final List<WeightAlertModel> activeAlerts;

  WeightPlanBundleModel({
    required this.athleteId,
    required this.latestPlan,
    required this.recentLogs,
    required this.activeAlerts,
  });

  factory WeightPlanBundleModel.fromJson(Map<String, dynamic> json) {
    return WeightPlanBundleModel(
      athleteId: json['athlete_id'] as int,
      latestPlan: json['latest_plan'] == null
          ? null
          : WeightPlanModel.fromJson(json['latest_plan'] as Map<String, dynamic>),
      recentLogs: (json['recent_logs'] as List<dynamic>? ?? [])
          .map((item) => WeightLogModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      activeAlerts: (json['active_alerts'] as List<dynamic>? ?? [])
          .map((item) => WeightAlertModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TeamWeightSnapshotModel {
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
  final String status;
  final String statusSummary;
  final String? warningMessage;
  final List<WeightAlertModel> alerts;

  TeamWeightSnapshotModel({
    required this.athleteId,
    required this.athleteName,
    required this.gradeLabel,
    required this.teamGroup,
    required this.currentWeight,
    required this.latestLogAt,
    required this.targetWeightClass,
    required this.targetDate,
    required this.projectedReachableWeight,
    required this.projectedClass,
    required this.weeklyAllowedLoss,
    required this.requiredWeeklyLoss,
    required this.status,
    required this.statusSummary,
    required this.warningMessage,
    required this.alerts,
  });

  factory TeamWeightSnapshotModel.fromJson(Map<String, dynamic> json) {
    return TeamWeightSnapshotModel(
      athleteId: json['athlete_id'] as int,
      athleteName: json['athlete_name'] as String,
      gradeLabel: json['grade_label'] as String?,
      teamGroup: json['team_group'] as String?,
      currentWeight: (json['current_weight'] as num?)?.toDouble(),
      latestLogAt: json['latest_log_at'] == null ? null : DateTime.parse(json['latest_log_at'] as String),
      targetWeightClass: (json['target_weight_class'] as num?)?.toDouble(),
      targetDate: json['target_date'] == null ? null : DateTime.parse(json['target_date'] as String),
      projectedReachableWeight: (json['projected_reachable_weight'] as num?)?.toDouble(),
      projectedClass: (json['projected_class'] as num?)?.toDouble(),
      weeklyAllowedLoss: (json['weekly_allowed_loss'] as num?)?.toDouble(),
      requiredWeeklyLoss: (json['required_weekly_loss'] as num?)?.toDouble(),
      status: json['status'] as String,
      statusSummary: json['status_summary'] as String,
      warningMessage: json['warning_message'] as String?,
      alerts: (json['alerts'] as List<dynamic>? ?? [])
          .map((item) => WeightAlertModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LinkedAthleteModel {
  final int athleteId;
  final String athleteName;
  final int teamId;
  final String relationshipLabel;

  LinkedAthleteModel({
    required this.athleteId,
    required this.athleteName,
    required this.teamId,
    required this.relationshipLabel,
  });

  factory LinkedAthleteModel.fromJson(Map<String, dynamic> json) {
    return LinkedAthleteModel(
      athleteId: json['athlete_id'] as int,
      athleteName: json['athlete_name'] as String,
      teamId: json['team_id'] as int,
      relationshipLabel: json['relationship_label'] as String,
    );
  }
}
