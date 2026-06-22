import 'dart:convert';

enum ScheduleEventType {
  practice,
  dualMeet,
  tournament,
  travel,
  teamMeeting,
  fundraiser,
}

enum PracticeBlockType {
  warmUp,
  stanceAndMotion,
  drilling,
  liveGoes,
  topBottom,
  neutral,
  conditioning,
  coolDown,
  filmReview,
  recovery,
}

ScheduleEventType scheduleEventTypeFromString(String value) {
  switch (value) {
    case 'dual_meet':
      return ScheduleEventType.dualMeet;
    case 'tournament':
      return ScheduleEventType.tournament;
    case 'travel':
      return ScheduleEventType.travel;
    case 'team_meeting':
      return ScheduleEventType.teamMeeting;
    case 'fundraiser':
      return ScheduleEventType.fundraiser;
    case 'practice':
    default:
      return ScheduleEventType.practice;
  }
}

String scheduleEventTypeToApi(ScheduleEventType value) {
  switch (value) {
    case ScheduleEventType.dualMeet:
      return 'dual_meet';
    case ScheduleEventType.tournament:
      return 'tournament';
    case ScheduleEventType.travel:
      return 'travel';
    case ScheduleEventType.teamMeeting:
      return 'team_meeting';
    case ScheduleEventType.fundraiser:
      return 'fundraiser';
    case ScheduleEventType.practice:
      return 'practice';
  }
}

String scheduleEventTypeLabel(ScheduleEventType value) {
  switch (value) {
    case ScheduleEventType.dualMeet:
      return 'Dual Meet';
    case ScheduleEventType.tournament:
      return 'Tournament';
    case ScheduleEventType.travel:
      return 'Travel';
    case ScheduleEventType.teamMeeting:
      return 'Team Meeting';
    case ScheduleEventType.fundraiser:
      return 'Fundraiser';
    case ScheduleEventType.practice:
      return 'Practice';
  }
}

PracticeBlockType practiceBlockTypeFromString(String value) {
  switch (value) {
    case 'stance_and_motion':
      return PracticeBlockType.stanceAndMotion;
    case 'drilling':
      return PracticeBlockType.drilling;
    case 'live_goes':
      return PracticeBlockType.liveGoes;
    case 'top_bottom':
      return PracticeBlockType.topBottom;
    case 'neutral':
      return PracticeBlockType.neutral;
    case 'conditioning':
      return PracticeBlockType.conditioning;
    case 'cool_down':
      return PracticeBlockType.coolDown;
    case 'film_review':
      return PracticeBlockType.filmReview;
    case 'recovery':
      return PracticeBlockType.recovery;
    case 'warm_up':
    default:
      return PracticeBlockType.warmUp;
  }
}

String practiceBlockTypeToApi(PracticeBlockType value) {
  switch (value) {
    case PracticeBlockType.stanceAndMotion:
      return 'stance_and_motion';
    case PracticeBlockType.drilling:
      return 'drilling';
    case PracticeBlockType.liveGoes:
      return 'live_goes';
    case PracticeBlockType.topBottom:
      return 'top_bottom';
    case PracticeBlockType.neutral:
      return 'neutral';
    case PracticeBlockType.conditioning:
      return 'conditioning';
    case PracticeBlockType.coolDown:
      return 'cool_down';
    case PracticeBlockType.filmReview:
      return 'film_review';
    case PracticeBlockType.recovery:
      return 'recovery';
    case PracticeBlockType.warmUp:
      return 'warm_up';
  }
}

String practiceBlockTypeLabel(PracticeBlockType value) {
  switch (value) {
    case PracticeBlockType.stanceAndMotion:
      return 'Stance + Motion';
    case PracticeBlockType.drilling:
      return 'Drilling';
    case PracticeBlockType.liveGoes:
      return 'Live Goes';
    case PracticeBlockType.topBottom:
      return 'Top / Bottom';
    case PracticeBlockType.neutral:
      return 'Neutral';
    case PracticeBlockType.conditioning:
      return 'Conditioning';
    case PracticeBlockType.coolDown:
      return 'Cool Down';
    case PracticeBlockType.filmReview:
      return 'Film Review';
    case PracticeBlockType.recovery:
      return 'Recovery';
    case PracticeBlockType.warmUp:
      return 'Warm-Up';
  }
}

class PracticeBlockItem {
  const PracticeBlockItem({
    required this.id,
    required this.blockOrder,
    required this.blockType,
    this.title,
    this.notes,
    required this.durationMinutes,
  });

  final int id;
  final int blockOrder;
  final PracticeBlockType blockType;
  final String? title;
  final String? notes;
  final int durationMinutes;

  factory PracticeBlockItem.fromMap(Map<String, dynamic> map) {
    return PracticeBlockItem(
      id: (map['id'] as num?)?.toInt() ?? 0,
      blockOrder: (map['block_order'] as num).toInt(),
      blockType: practiceBlockTypeFromString(map['block_type'] as String),
      title: map['title'] as String?,
      notes: map['notes'] as String?,
      durationMinutes: (map['duration_minutes'] as num).toInt(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'block_order': blockOrder,
      'block_type': practiceBlockTypeToApi(blockType),
      'title': title,
      'notes': notes,
      'duration_minutes': durationMinutes,
    };
  }

  PracticeBlockItem copyWith({
    int? id,
    int? blockOrder,
    PracticeBlockType? blockType,
    String? title,
    String? notes,
    int? durationMinutes,
  }) {
    return PracticeBlockItem(
      id: id ?? this.id,
      blockOrder: blockOrder ?? this.blockOrder,
      blockType: blockType ?? this.blockType,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}

class PracticePlanItem {
  const PracticePlanItem({
    required this.id,
    required this.teamId,
    required this.createdByUserId,
    this.templateId,
    required this.title,
    this.description,
    this.focus,
    this.practiceDate,
    this.notes,
    required this.totalDurationMinutes,
    this.templateNameSnapshot,
    required this.isTemplateBased,
    required this.createdAt,
    required this.updatedAt,
    required this.blocks,
    required this.totalBlockCount,
  });

  final int id;
  final int teamId;
  final int createdByUserId;
  final int? templateId;
  final String title;
  final String? description;
  final String? focus;
  final DateTime? practiceDate;
  final String? notes;
  final int totalDurationMinutes;
  final String? templateNameSnapshot;
  final bool isTemplateBased;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PracticeBlockItem> blocks;
  final int totalBlockCount;

  factory PracticePlanItem.fromMap(Map<String, dynamic> map) {
    return PracticePlanItem(
      id: map['id'] as int,
      teamId: map['team_id'] as int,
      createdByUserId: map['created_by_user_id'] as int,
      templateId: map['template_id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      focus: map['focus'] as String?,
      practiceDate: map['practice_date'] != null
          ? DateTime.parse(map['practice_date'] as String)
          : null,
      notes: map['notes'] as String?,
      totalDurationMinutes: (map['total_duration_minutes'] as num).toInt(),
      templateNameSnapshot: map['template_name_snapshot'] as String?,
      isTemplateBased: map['is_template_based'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      blocks: ((map['blocks'] as List?) ?? const [])
          .map(
            (item) =>
                PracticeBlockItem.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(),
      totalBlockCount:
          (map['total_block_count'] as num?)?.toInt() ??
          (((map['blocks'] as List?) ?? const []).length),
    );
  }
}

class PracticePlanSummaryItem {
  const PracticePlanSummaryItem({
    required this.id,
    required this.title,
    this.practiceDate,
    this.focus,
    required this.totalDurationMinutes,
    this.templateNameSnapshot,
    required this.totalBlockCount,
  });

  final int id;
  final String title;
  final DateTime? practiceDate;
  final String? focus;
  final int totalDurationMinutes;
  final String? templateNameSnapshot;
  final int totalBlockCount;

  factory PracticePlanSummaryItem.fromMap(Map<String, dynamic> map) {
    return PracticePlanSummaryItem(
      id: map['id'] as int,
      title: map['title'] as String,
      practiceDate: map['practice_date'] != null
          ? DateTime.parse(map['practice_date'] as String)
          : null,
      focus: map['focus'] as String?,
      totalDurationMinutes: (map['total_duration_minutes'] as num).toInt(),
      templateNameSnapshot: map['template_name_snapshot'] as String?,
      totalBlockCount: (map['total_block_count'] as num).toInt(),
    );
  }
}

class PracticeTemplateItem {
  const PracticeTemplateItem({
    required this.id,
    required this.teamId,
    required this.createdByUserId,
    required this.templateName,
    this.description,
    this.focus,
    required this.totalDurationMinutes,
    required this.isSystemTemplate,
    required this.createdAt,
    required this.updatedAt,
    required this.blocks,
  });

  final int id;
  final int teamId;
  final int createdByUserId;
  final String templateName;
  final String? description;
  final String? focus;
  final int totalDurationMinutes;
  final bool isSystemTemplate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PracticeBlockItem> blocks;

  factory PracticeTemplateItem.fromMap(Map<String, dynamic> map) {
    return PracticeTemplateItem(
      id: map['id'] as int,
      teamId: map['team_id'] as int,
      createdByUserId: map['created_by_user_id'] as int,
      templateName: map['template_name'] as String,
      description: map['description'] as String?,
      focus: map['focus'] as String?,
      totalDurationMinutes: (map['total_duration_minutes'] as num).toInt(),
      isSystemTemplate: map['is_system_template'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      blocks: ((map['blocks'] as List?) ?? const [])
          .map(
            (item) =>
                PracticeBlockItem.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class ScheduleEventItem {
  const ScheduleEventItem({
    required this.id,
    required this.teamId,
    required this.createdByUserId,
    this.practicePlanId,
    required this.title,
    this.description,
    required this.eventType,
    required this.startsAt,
    required this.endsAt,
    this.location,
    this.notes,
    required this.checklist,
    this.busDepartureNote,
    this.weighInNote,
    required this.isCancelled,
    required this.createdAt,
    required this.updatedAt,
    this.practicePlan,
    required this.totalMinutes,
  });

  final int id;
  final int teamId;
  final int createdByUserId;
  final int? practicePlanId;
  final String title;
  final String? description;
  final ScheduleEventType eventType;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? location;
  final String? notes;
  final List<String> checklist;
  final String? busDepartureNote;
  final String? weighInNote;
  final bool isCancelled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PracticePlanItem? practicePlan;
  final int totalMinutes;

  factory ScheduleEventItem.fromMap(Map<String, dynamic> map) {
    return ScheduleEventItem(
      id: map['id'] as int,
      teamId: map['team_id'] as int,
      createdByUserId: map['created_by_user_id'] as int,
      practicePlanId: map['practice_plan_id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      eventType: scheduleEventTypeFromString(map['event_type'] as String),
      startsAt: DateTime.parse(map['starts_at'] as String).toLocal(),
      endsAt: DateTime.parse(map['ends_at'] as String).toLocal(),
      location: map['location'] as String?,
      notes: map['notes'] as String?,
      checklist: ((map['checklist'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(),
      busDepartureNote: map['bus_departure_note'] as String?,
      weighInNote: map['weigh_in_note'] as String?,
      isCancelled: map['is_cancelled'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      practicePlan: map['practice_plan'] != null
          ? PracticePlanItem.fromMap(
              Map<String, dynamic>.from(map['practice_plan'] as Map),
            )
          : null,
      totalMinutes:
          (map['total_minutes'] as num?)?.toInt() ??
          DateTime.parse(
            map['ends_at'] as String,
          ).difference(DateTime.parse(map['starts_at'] as String)).inMinutes,
    );
  }
}

class ScheduleSummary {
  const ScheduleSummary({
    required this.totalEvents,
    required this.practiceCount,
    required this.competitionCount,
    required this.travelCount,
    required this.meetingCount,
    required this.fundraiserCount,
    required this.upcomingWeekCount,
  });

  final int totalEvents;
  final int practiceCount;
  final int competitionCount;
  final int travelCount;
  final int meetingCount;
  final int fundraiserCount;
  final int upcomingWeekCount;

  factory ScheduleSummary.fromMap(Map<String, dynamic> map) {
    return ScheduleSummary(
      totalEvents: (map['total_events'] as num).toInt(),
      practiceCount: (map['practice_count'] as num).toInt(),
      competitionCount: (map['competition_count'] as num).toInt(),
      travelCount: (map['travel_count'] as num).toInt(),
      meetingCount: (map['meeting_count'] as num).toInt(),
      fundraiserCount: (map['fundraiser_count'] as num).toInt(),
      upcomingWeekCount: (map['upcoming_week_count'] as num).toInt(),
    );
  }
}

class TeamScheduleBundle {
  const TeamScheduleBundle({
    required this.teamId,
    required this.visibleAs,
    required this.summary,
    required this.events,
  });

  final int teamId;
  final String visibleAs;
  final ScheduleSummary summary;
  final List<ScheduleEventItem> events;

  factory TeamScheduleBundle.fromMap(Map<String, dynamic> map) {
    return TeamScheduleBundle(
      teamId: map['team_id'] as int,
      visibleAs: map['visible_as'] as String,
      summary: ScheduleSummary.fromMap(
        Map<String, dynamic>.from(map['summary'] as Map),
      ),
      events: ((map['events'] as List?) ?? const [])
          .map(
            (item) =>
                ScheduleEventItem.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class PracticeAssignmentResult {
  const PracticeAssignmentResult({required this.practice, required this.event});

  final PracticePlanItem practice;
  final ScheduleEventItem event;

  factory PracticeAssignmentResult.fromMap(Map<String, dynamic> map) {
    return PracticeAssignmentResult(
      practice: PracticePlanItem.fromMap(
        Map<String, dynamic>.from(map['practice'] as Map),
      ),
      event: ScheduleEventItem.fromMap(
        Map<String, dynamic>.from(map['event'] as Map),
      ),
    );
  }
}

Map<String, dynamic> decodeScheduleObject(String body) =>
    Map<String, dynamic>.from(jsonDecode(body) as Map);

List<Map<String, dynamic>> decodeScheduleList(String body) =>
    (jsonDecode(body) as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
