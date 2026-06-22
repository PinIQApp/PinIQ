import 'user_profile.dart';

class ParentLinkModel {
  final int id;
  final int teamId;
  final int parentUserId;
  final int athleteUserId;
  final String relationshipLabel;
  final bool isActive;

  ParentLinkModel({
    required this.id,
    required this.teamId,
    required this.parentUserId,
    required this.athleteUserId,
    required this.relationshipLabel,
    required this.isActive,
  });

  factory ParentLinkModel.fromJson(Map<String, dynamic> json) {
    return ParentLinkModel(
      id: json['id'] as int,
      teamId: json['team_id'] as int,
      parentUserId: json['parent_user_id'] as int,
      athleteUserId: json['athlete_user_id'] as int,
      relationshipLabel: json['relationship_label'] as String,
      isActive: json['is_active'] as bool,
    );
  }
}

class AnnouncementModel {
  final int id;
  final int threadId;
  final int teamId;
  final int senderId;
  final String title;
  final String body;
  final String audienceLabel;
  final Map<String, dynamic>? visibilityFlags;
  final int auditVersion;
  final DateTime createdAt;
  final UserProfile sender;

  AnnouncementModel({
    required this.id,
    required this.threadId,
    required this.teamId,
    required this.senderId,
    required this.title,
    required this.body,
    required this.audienceLabel,
    required this.visibilityFlags,
    required this.auditVersion,
    required this.createdAt,
    required this.sender,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as int,
      threadId: json['thread_id'] as int,
      teamId: json['team_id'] as int,
      senderId: json['sender_id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      audienceLabel: json['audience_label'] as String,
      visibilityFlags: json['visibility_flags'] as Map<String, dynamic>?,
      auditVersion: json['audit_version'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      sender: UserProfile.fromJson(json['sender'] as Map<String, dynamic>),
    );
  }

  bool get isTeamTextAlert => visibilityFlags?['team_text_alert'] == true;
  Map<String, dynamic>? get textAlertDelivery =>
      visibilityFlags?['text_alert_delivery'] as Map<String, dynamic>?;
  int get smsSentCount => textAlertDelivery?['sms_sent_count'] as int? ?? 0;
  int get smsFailedCount => textAlertDelivery?['sms_failed_count'] as int? ?? 0;
  int get emailSentCount => textAlertDelivery?['email_sent_count'] as int? ?? 0;
  int get pushSentCount => textAlertDelivery?['push_sent_count'] as int? ?? 0;
}

class TeamTextAlertReadinessMemberModel {
  final int userId;
  final String fullName;
  final String role;
  final String? phone;
  final bool hasValidPhone;
  final String? normalizedPhone;
  final String? autoIncludedReason;

  TeamTextAlertReadinessMemberModel({
    required this.userId,
    required this.fullName,
    required this.role,
    required this.phone,
    required this.hasValidPhone,
    required this.normalizedPhone,
    required this.autoIncludedReason,
  });

  bool get isAutoIncludedParent => autoIncludedReason != null && autoIncludedReason!.isNotEmpty;

  factory TeamTextAlertReadinessMemberModel.fromJson(Map<String, dynamic> json) {
    return TeamTextAlertReadinessMemberModel(
      userId: json['user_id'] as int,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      phone: json['phone'] as String?,
      hasValidPhone: json['has_valid_phone'] as bool,
      normalizedPhone: json['normalized_phone'] as String?,
      autoIncludedReason: json['auto_included_reason'] as String?,
    );
  }
}

class TeamTextAlertReadinessSummaryModel {
  final int eligibleRecipientCount;
  final int validPhoneRecipientCount;
  final int missingPhoneRecipientCount;
  final int coachCount;
  final int athleteCount;
  final int parentCount;

  TeamTextAlertReadinessSummaryModel({
    required this.eligibleRecipientCount,
    required this.validPhoneRecipientCount,
    required this.missingPhoneRecipientCount,
    required this.coachCount,
    required this.athleteCount,
    required this.parentCount,
  });

  factory TeamTextAlertReadinessSummaryModel.fromJson(Map<String, dynamic> json) {
    return TeamTextAlertReadinessSummaryModel(
      eligibleRecipientCount: json['eligible_recipient_count'] as int,
      validPhoneRecipientCount: json['valid_phone_recipient_count'] as int,
      missingPhoneRecipientCount: json['missing_phone_recipient_count'] as int,
      coachCount: json['coach_count'] as int,
      athleteCount: json['athlete_count'] as int,
      parentCount: json['parent_count'] as int,
    );
  }
}

class TeamTextAlertReadinessModel {
  final int teamId;
  final TeamTextAlertReadinessSummaryModel summary;
  final List<TeamTextAlertReadinessMemberModel> members;

  TeamTextAlertReadinessModel({
    required this.teamId,
    required this.summary,
    required this.members,
  });

  factory TeamTextAlertReadinessModel.fromJson(Map<String, dynamic> json) {
    return TeamTextAlertReadinessModel(
      teamId: json['team_id'] as int,
      summary: TeamTextAlertReadinessSummaryModel.fromJson(
        json['summary'] as Map<String, dynamic>,
      ),
      members: (json['members'] as List<dynamic>? ?? [])
          .map((item) => TeamTextAlertReadinessMemberModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MessageParticipantModel {
  final int id;
  final int teamId;
  final int userId;
  final String participantType;
  final Map<String, dynamic>? visibilityFlags;
  final DateTime createdAt;
  final UserProfile user;

  MessageParticipantModel({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.participantType,
    required this.visibilityFlags,
    required this.createdAt,
    required this.user,
  });

  bool get isParentVisibility => participantType == 'parent_visibility';

  factory MessageParticipantModel.fromJson(Map<String, dynamic> json) {
    return MessageParticipantModel(
      id: json['id'] as int,
      teamId: json['team_id'] as int,
      userId: json['user_id'] as int,
      participantType: json['participant_type'] as String,
      visibilityFlags: json['visibility_flags'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class MessageModel {
  final int id;
  final int threadId;
  final int teamId;
  final int senderId;
  final String body;
  final String messageType;
  final Map<String, dynamic>? visibilityFlags;
  final int auditVersion;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final UserProfile sender;

  MessageModel({
    required this.id,
    required this.threadId,
    required this.teamId,
    required this.senderId,
    required this.body,
    required this.messageType,
    required this.visibilityFlags,
    required this.auditVersion,
    required this.createdAt,
    required this.updatedAt,
    required this.editedAt,
    required this.deletedAt,
    required this.sender,
  });

  List<String> get contentRiskFlags => (visibilityFlags?['content_risk_flags'] as List<dynamic>? ?? [])
      .map((item) => item.toString())
      .toList();
  String? get severity => visibilityFlags?['severity']?.toString();
  int? get score => visibilityFlags?['score'] as int?;
  bool get autoEscalated => visibilityFlags?['auto_escalated_to_parent_and_coaches'] == true;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int,
      threadId: json['thread_id'] as int,
      teamId: json['team_id'] as int,
      senderId: json['sender_id'] as int,
      body: json['body'] as String,
      messageType: json['message_type'] as String,
      visibilityFlags: json['visibility_flags'] as Map<String, dynamic>?,
      auditVersion: json['audit_version'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      editedAt: json['edited_at'] == null ? null : DateTime.parse(json['edited_at'] as String),
      deletedAt: json['deleted_at'] == null ? null : DateTime.parse(json['deleted_at'] as String),
      sender: UserProfile.fromJson(json['sender'] as Map<String, dynamic>),
    );
  }
}

class MessageThreadSummaryModel {
  final int id;
  final int teamId;
  final String title;
  final String threadType;
  final bool parentVisibilityRequired;
  final bool isComplianceLocked;
  final Map<String, dynamic>? visibilityFlags;
  final int auditVersion;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final List<MessageParticipantModel> participants;
  final String? lastMessagePreview;

  MessageThreadSummaryModel({
    required this.id,
    required this.teamId,
    required this.title,
    required this.threadType,
    required this.parentVisibilityRequired,
    required this.isComplianceLocked,
    required this.visibilityFlags,
    required this.auditVersion,
    required this.lastMessageAt,
    required this.createdAt,
    required this.participants,
    required this.lastMessagePreview,
  });

  bool get isGroup => threadType == 'group';
  bool get isAnnouncement => threadType == 'announcement';
  bool get isDirect => threadType == 'direct';
  bool get isSafetyAlertThread => visibilityFlags?['compliance_alert'] == true;
  String? get safetySeverity => visibilityFlags?['severity']?.toString();

  factory MessageThreadSummaryModel.fromJson(Map<String, dynamic> json) {
    return MessageThreadSummaryModel(
      id: json['id'] as int,
      teamId: json['team_id'] as int,
      title: json['title'] as String,
      threadType: json['thread_type'] as String,
      parentVisibilityRequired: json['parent_visibility_required'] as bool,
      isComplianceLocked: json['is_compliance_locked'] as bool,
      visibilityFlags: json['visibility_flags'] as Map<String, dynamic>?,
      auditVersion: json['audit_version'] as int,
      lastMessageAt: DateTime.parse(json['last_message_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      participants: (json['participants'] as List<dynamic>? ?? [])
          .map((item) => MessageParticipantModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      lastMessagePreview: json['last_message_preview'] as String?,
    );
  }
}

class MessageThreadDetailModel extends MessageThreadSummaryModel {
  final List<MessageModel> messages;

  MessageThreadDetailModel({
    required super.id,
    required super.teamId,
    required super.title,
    required super.threadType,
    required super.parentVisibilityRequired,
    required super.isComplianceLocked,
    required super.visibilityFlags,
    required super.auditVersion,
    required super.lastMessageAt,
    required super.createdAt,
    required super.participants,
    required super.lastMessagePreview,
    required this.messages,
  });

  factory MessageThreadDetailModel.fromJson(Map<String, dynamic> json) {
    final summary = MessageThreadSummaryModel.fromJson(json);
    return MessageThreadDetailModel(
      id: summary.id,
      teamId: summary.teamId,
      title: summary.title,
      threadType: summary.threadType,
      parentVisibilityRequired: summary.parentVisibilityRequired,
      isComplianceLocked: summary.isComplianceLocked,
      visibilityFlags: summary.visibilityFlags,
      auditVersion: summary.auditVersion,
      lastMessageAt: summary.lastMessageAt,
      createdAt: summary.createdAt,
      participants: summary.participants,
      lastMessagePreview: summary.lastMessagePreview,
      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((item) => MessageModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SafetyAlertModel {
  final int id;
  final int teamId;
  final int sourceThreadId;
  final int sourceMessageId;
  final int alertThreadId;
  final int sourceSenderId;
  final String severity;
  final String status;
  final int score;
  final List<String> categories;
  final int repeatedTriggerCount;
  final List<int> subjectAthleteIds;
  final String summary;
  final String sourceExcerpt;
  final Map<String, dynamic>? metadata;
  final DateTime? acknowledgedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserProfile sourceSender;
  final UserProfile? acknowledgedBy;

  SafetyAlertModel({
    required this.id,
    required this.teamId,
    required this.sourceThreadId,
    required this.sourceMessageId,
    required this.alertThreadId,
    required this.sourceSenderId,
    required this.severity,
    required this.status,
    required this.score,
    required this.categories,
    required this.repeatedTriggerCount,
    required this.subjectAthleteIds,
    required this.summary,
    required this.sourceExcerpt,
    required this.metadata,
    required this.acknowledgedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.sourceSender,
    required this.acknowledgedBy,
  });

  bool get isOpen => status == 'open';
  bool get isUrgent => severity == 'urgent';

  factory SafetyAlertModel.fromJson(Map<String, dynamic> json) {
    return SafetyAlertModel(
      id: json['id'] as int,
      teamId: json['team_id'] as int,
      sourceThreadId: json['source_thread_id'] as int,
      sourceMessageId: json['source_message_id'] as int,
      alertThreadId: json['alert_thread_id'] as int,
      sourceSenderId: json['source_sender_id'] as int,
      severity: json['severity'] as String,
      status: json['status'] as String,
      score: json['score'] as int,
      categories: (json['categories'] as List<dynamic>? ?? []).map((item) => item.toString()).toList(),
      repeatedTriggerCount: json['repeated_trigger_count'] as int? ?? 0,
      subjectAthleteIds: (json['subject_athlete_ids'] as List<dynamic>? ?? [])
          .map((item) => item as int)
          .toList(),
      summary: json['summary'] as String,
      sourceExcerpt: json['source_excerpt'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      acknowledgedAt: json['acknowledged_at'] == null
          ? null
          : DateTime.parse(json['acknowledged_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      sourceSender: UserProfile.fromJson(json['source_sender'] as Map<String, dynamic>),
      acknowledgedBy: json['acknowledged_by'] == null
          ? null
          : UserProfile.fromJson(json['acknowledged_by'] as Map<String, dynamic>),
    );
  }
}
