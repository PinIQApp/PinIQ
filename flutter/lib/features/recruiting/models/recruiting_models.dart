import 'dart:convert';

RecruitingVisibilityLevel recruitingVisibilityLevelFromString(String value) {
  switch (value) {
    case 'public':
      return RecruitingVisibilityLevel.publicProfile;
    case 'private':
      return RecruitingVisibilityLevel.privateProfile;
    case 'coaches_only':
    default:
      return RecruitingVisibilityLevel.coachesOnly;
  }
}

String recruitingVisibilityLevelToApi(RecruitingVisibilityLevel value) {
  switch (value) {
    case RecruitingVisibilityLevel.publicProfile:
      return 'public';
    case RecruitingVisibilityLevel.privateProfile:
      return 'private';
    case RecruitingVisibilityLevel.coachesOnly:
      return 'coaches_only';
  }
}

RecruitingContactVisibility recruitingContactVisibilityFromString(String value) {
  switch (value) {
    case 'full':
      return RecruitingContactVisibility.full;
    case 'coaches_only':
      return RecruitingContactVisibility.coachesOnly;
    case 'hidden':
    default:
      return RecruitingContactVisibility.hidden;
  }
}

String recruitingContactVisibilityToApi(RecruitingContactVisibility value) {
  switch (value) {
    case RecruitingContactVisibility.full:
      return 'full';
    case RecruitingContactVisibility.coachesOnly:
      return 'coaches_only';
    case RecruitingContactVisibility.hidden:
      return 'hidden';
  }
}

enum RecruitingVisibilityLevel { publicProfile, coachesOnly, privateProfile }

enum RecruitingContactVisibility { hidden, coachesOnly, full }

class RecruitingStatMetric {
  const RecruitingStatMetric({
    required this.label,
    required this.value,
    this.numericValue,
  });

  final String label;
  final String value;
  final double? numericValue;

  factory RecruitingStatMetric.fromMap(Map<String, dynamic> map) {
    return RecruitingStatMetric(
      label: map['label'] as String,
      value: map['value'] as String,
      numericValue: (map['numeric_value'] as num?)?.toDouble(),
    );
  }
}

class RecruitingHighlight {
  const RecruitingHighlight({
    required this.id,
    required this.athleteId,
    required this.profileId,
    required this.title,
    required this.highlightUrl,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int athleteId;
  final int profileId;
  final String title;
  final String highlightUrl;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory RecruitingHighlight.fromMap(Map<String, dynamic> map) {
    return RecruitingHighlight(
      id: map['id'] as int,
      athleteId: map['athlete_id'] as int,
      profileId: map['profile_id'] as int,
      title: map['title'] as String,
      highlightUrl: map['highlight_url'] as String,
      sortOrder: (map['sort_order'] as num).toInt(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class RecruitingVisibilitySettings {
  const RecruitingVisibilitySettings({
    required this.id,
    required this.profileId,
    required this.showContactToCoaches,
    required this.showGpa,
    required this.showLocation,
    required this.showProfilePhoto,
    required this.parentVisibilityRequired,
    required this.allowDirectContactRequest,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int profileId;
  final bool showContactToCoaches;
  final bool showGpa;
  final bool showLocation;
  final bool showProfilePhoto;
  final bool parentVisibilityRequired;
  final bool allowDirectContactRequest;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory RecruitingVisibilitySettings.fromMap(Map<String, dynamic> map) {
    return RecruitingVisibilitySettings(
      id: map['id'] as int,
      profileId: map['profile_id'] as int,
      showContactToCoaches: map['show_contact_to_coaches'] as bool? ?? false,
      showGpa: map['show_gpa'] as bool? ?? false,
      showLocation: map['show_location'] as bool? ?? false,
      showProfilePhoto: map['show_profile_photo'] as bool? ?? false,
      parentVisibilityRequired: map['parent_visibility_required'] as bool? ?? false,
      allowDirectContactRequest: map['allow_direct_contact_request'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'show_contact_to_coaches': showContactToCoaches,
      'show_gpa': showGpa,
      'show_location': showLocation,
      'show_profile_photo': showProfilePhoto,
      'parent_visibility_required': parentVisibilityRequired,
      'allow_direct_contact_request': allowDirectContactRequest,
    };
  }
}

class RecruitingContact {
  const RecruitingContact({
    this.email,
    this.phone,
    required this.visibleToViewer,
    this.complianceMessage,
    required this.messagingEntrypoint,
  });

  final String? email;
  final String? phone;
  final bool visibleToViewer;
  final String? complianceMessage;
  final String messagingEntrypoint;

  factory RecruitingContact.fromMap(Map<String, dynamic> map) {
    return RecruitingContact(
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      visibleToViewer: map['visible_to_viewer'] as bool? ?? false,
      complianceMessage: map['compliance_message'] as String?,
      messagingEntrypoint: map['messaging_entrypoint'] as String? ?? '/api/v1/messages',
    );
  }
}

class RecruitingRecentMatch {
  const RecruitingRecentMatch({
    required this.id,
    required this.opponentName,
    this.opponentSchool,
    this.eventName,
    required this.matchDate,
    required this.weightClass,
    required this.result,
    required this.resultType,
    required this.scoreDisplay,
  });

  final int id;
  final String opponentName;
  final String? opponentSchool;
  final String? eventName;
  final DateTime matchDate;
  final String weightClass;
  final String result;
  final String resultType;
  final String scoreDisplay;

  factory RecruitingRecentMatch.fromMap(Map<String, dynamic> map) {
    return RecruitingRecentMatch(
      id: map['id'] as int,
      opponentName: map['opponent_name'] as String,
      opponentSchool: map['opponent_school'] as String?,
      eventName: map['event_name'] as String?,
      matchDate: DateTime.parse(map['match_date'] as String),
      weightClass: map['weight_class'] as String,
      result: map['result'] as String,
      resultType: map['result_type'] as String,
      scoreDisplay: map['score_display'] as String,
    );
  }
}

class RecruitingAthleteCard {
  const RecruitingAthleteCard({
    required this.athleteId,
    required this.profileId,
    required this.athleteName,
    this.schoolTeam,
    this.locationLabel,
    required this.graduationYear,
    required this.weightClass,
    this.height,
    this.profileImageUrl,
    required this.isOpen,
    required this.isActivelyLooking,
    required this.isFeatured,
    required this.visibilityLevel,
    required this.record,
    this.trendLabel,
    this.winPercentage,
    this.bonusPointRate,
    required this.statsMetrics,
    required this.achievements,
    required this.highlightCount,
    required this.updatedAt,
    required this.trendingScore,
    required this.savedByCoach,
    required this.tags,
  });

  final int athleteId;
  final int profileId;
  final String athleteName;
  final String? schoolTeam;
  final String? locationLabel;
  final int graduationYear;
  final String weightClass;
  final String? height;
  final String? profileImageUrl;
  final bool isOpen;
  final bool isActivelyLooking;
  final bool isFeatured;
  final RecruitingVisibilityLevel visibilityLevel;
  final String record;
  final String? trendLabel;
  final double? winPercentage;
  final double? bonusPointRate;
  final List<RecruitingStatMetric> statsMetrics;
  final List<String> achievements;
  final int highlightCount;
  final DateTime updatedAt;
  final double trendingScore;
  final bool savedByCoach;
  final List<String> tags;

  factory RecruitingAthleteCard.fromMap(Map<String, dynamic> map) {
    return RecruitingAthleteCard(
      athleteId: map['athlete_id'] as int,
      profileId: map['profile_id'] as int,
      athleteName: map['athlete_name'] as String,
      schoolTeam: map['school_team'] as String?,
      locationLabel: map['location_label'] as String?,
      graduationYear: map['graduation_year'] as int,
      weightClass: map['weight_class'] as String,
      height: map['height'] as String?,
      profileImageUrl: map['profile_image_url'] as String?,
      isOpen: map['is_open'] as bool? ?? false,
      isActivelyLooking: map['is_actively_looking'] as bool? ?? false,
      isFeatured: map['is_featured'] as bool? ?? false,
      visibilityLevel: recruitingVisibilityLevelFromString(map['visibility_level'] as String),
      record: map['record'] as String? ?? '0-0',
      trendLabel: map['trend_label'] as String?,
      winPercentage: (map['win_percentage'] as num?)?.toDouble(),
      bonusPointRate: (map['bonus_point_rate'] as num?)?.toDouble(),
      statsMetrics: ((map['stats_metrics'] as List?) ?? const [])
          .map((item) => RecruitingStatMetric.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      achievements: ((map['achievements'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      highlightCount: (map['highlight_count'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.parse(map['updated_at'] as String),
      trendingScore: (map['trending_score'] as num?)?.toDouble() ?? 0,
      savedByCoach: map['saved_by_coach'] as bool? ?? false,
      tags: ((map['tags'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }
}

class RecruitingProfileDetail {
  const RecruitingProfileDetail({
    required this.athleteId,
    required this.profileId,
    required this.athleteName,
    this.teamId,
    this.schoolTeam,
    required this.graduationYear,
    required this.weightClass,
    this.height,
    this.gpa,
    this.bio,
    required this.achievements,
    this.locationLabel,
    this.profileImageUrl,
    required this.isOpen,
    required this.isActivelyLooking,
    required this.isFeatured,
    required this.boostRequested,
    required this.visibilityLevel,
    required this.contactVisibility,
    required this.statsMetrics,
    required this.record,
    required this.recentMatches,
    required this.highlights,
    required this.contact,
    required this.visibility,
    required this.visibleAs,
    required this.parentVisibilityRequired,
    required this.updatedAt,
  });

  final int athleteId;
  final int profileId;
  final String athleteName;
  final int? teamId;
  final String? schoolTeam;
  final int graduationYear;
  final String weightClass;
  final String? height;
  final String? gpa;
  final String? bio;
  final List<String> achievements;
  final String? locationLabel;
  final String? profileImageUrl;
  final bool isOpen;
  final bool isActivelyLooking;
  final bool isFeatured;
  final bool boostRequested;
  final RecruitingVisibilityLevel visibilityLevel;
  final RecruitingContactVisibility contactVisibility;
  final List<RecruitingStatMetric> statsMetrics;
  final String record;
  final List<RecruitingRecentMatch> recentMatches;
  final List<RecruitingHighlight> highlights;
  final RecruitingContact contact;
  final RecruitingVisibilitySettings visibility;
  final String visibleAs;
  final bool parentVisibilityRequired;
  final DateTime updatedAt;

  factory RecruitingProfileDetail.fromMap(Map<String, dynamic> map) {
    return RecruitingProfileDetail(
      athleteId: map['athlete_id'] as int,
      profileId: map['profile_id'] as int,
      athleteName: map['athlete_name'] as String,
      teamId: map['team_id'] as int?,
      schoolTeam: map['school_team'] as String?,
      graduationYear: map['graduation_year'] as int,
      weightClass: map['weight_class'] as String,
      height: map['height'] as String?,
      gpa: map['gpa'] as String?,
      bio: map['bio'] as String?,
      achievements: ((map['achievements'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      locationLabel: map['location_label'] as String?,
      profileImageUrl: map['profile_image_url'] as String?,
      isOpen: map['is_open'] as bool? ?? false,
      isActivelyLooking: map['is_actively_looking'] as bool? ?? false,
      isFeatured: map['is_featured'] as bool? ?? false,
      boostRequested: map['boost_requested'] as bool? ?? false,
      visibilityLevel: recruitingVisibilityLevelFromString(map['visibility_level'] as String),
      contactVisibility: recruitingContactVisibilityFromString(map['contact_visibility'] as String),
      statsMetrics: ((map['stats_metrics'] as List?) ?? const [])
          .map((item) => RecruitingStatMetric.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      record: map['record'] as String? ?? '0-0',
      recentMatches: ((map['recent_matches'] as List?) ?? const [])
          .map((item) => RecruitingRecentMatch.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      highlights: ((map['highlights'] as List?) ?? const [])
          .map((item) => RecruitingHighlight.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      contact: RecruitingContact.fromMap(Map<String, dynamic>.from(map['contact'] as Map)),
      visibility: RecruitingVisibilitySettings.fromMap(Map<String, dynamic>.from(map['visibility'] as Map)),
      visibleAs: map['visible_as'] as String? ?? 'public',
      parentVisibilityRequired: map['parent_visibility_required'] as bool? ?? false,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class RecruitingBoard {
  const RecruitingBoard({
    required this.trendingAthletes,
    required this.featuredAthletes,
    required this.recentlyUpdated,
    required this.topPerformers,
  });

  final List<RecruitingAthleteCard> trendingAthletes;
  final List<RecruitingAthleteCard> featuredAthletes;
  final List<RecruitingAthleteCard> recentlyUpdated;
  final List<RecruitingAthleteCard> topPerformers;

  factory RecruitingBoard.fromMap(Map<String, dynamic> map) {
    List<RecruitingAthleteCard> parseList(String key) {
      return ((map[key] as List?) ?? const [])
          .map((item) => RecruitingAthleteCard.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    }

    return RecruitingBoard(
      trendingAthletes: parseList('trending_athletes'),
      featuredAthletes: parseList('featured_athletes'),
      recentlyUpdated: parseList('recently_updated'),
      topPerformers: parseList('top_performers'),
    );
  }
}

class RecruitingWatchlistEntry {
  const RecruitingWatchlistEntry({
    required this.id,
    required this.coachId,
    required this.athleteId,
    required this.createdAt,
    required this.athlete,
    this.note,
    required this.tags,
  });

  final int id;
  final int coachId;
  final int athleteId;
  final DateTime createdAt;
  final RecruitingAthleteCard athlete;
  final String? note;
  final List<String> tags;

  factory RecruitingWatchlistEntry.fromMap(Map<String, dynamic> map) {
    return RecruitingWatchlistEntry(
      id: map['id'] as int,
      coachId: map['coach_id'] as int,
      athleteId: map['athlete_id'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      athlete: RecruitingAthleteCard.fromMap(Map<String, dynamic>.from(map['athlete'] as Map)),
      note: map['note'] as String?,
      tags: ((map['tags'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }
}

class RecruitingTrendingBundle {
  const RecruitingTrendingBundle({
    required this.generatedAt,
    required this.athletes,
  });

  final DateTime generatedAt;
  final List<RecruitingAthleteCard> athletes;

  factory RecruitingTrendingBundle.fromMap(Map<String, dynamic> map) {
    return RecruitingTrendingBundle(
      generatedAt: DateTime.parse(map['generated_at'] as String),
      athletes: ((map['athletes'] as List?) ?? const [])
          .map((item) => RecruitingAthleteCard.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false),
    );
  }
}

class RecruitingSearchResponseModel {
  const RecruitingSearchResponseModel({
    required this.results,
    required this.total,
    required this.filtersApplied,
  });

  final List<RecruitingAthleteCard> results;
  final int total;
  final Map<String, dynamic> filtersApplied;

  factory RecruitingSearchResponseModel.fromMap(Map<String, dynamic> map) {
    return RecruitingSearchResponseModel(
      results: ((map['results'] as List?) ?? const [])
          .map((item) => RecruitingAthleteCard.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      total: (map['total'] as num?)?.toInt() ?? 0,
      filtersApplied: Map<String, dynamic>.from(map['filters_applied'] as Map? ?? const {}),
    );
  }
}

class RecruitingProfileDraft {
  RecruitingProfileDraft({
    required this.athleteId,
    this.teamId,
    required this.graduationYear,
    required this.schoolTeam,
    required this.weightClass,
    required this.height,
    required this.gpa,
    required this.bio,
    required this.achievements,
    required this.contactEmail,
    required this.contactPhone,
    required this.locationLabel,
    required this.profileImageUrl,
    required this.isOpen,
    required this.isActivelyLooking,
    required this.isFeatured,
    required this.boostRequested,
    required this.visibilityLevel,
    required this.contactVisibility,
    required this.visibilitySettings,
    required this.highlights,
    required this.statsSummary,
    this.matchRecordOverride,
  });

  final int athleteId;
  final int? teamId;
  final int graduationYear;
  final String schoolTeam;
  final String weightClass;
  final String height;
  final String gpa;
  final String bio;
  final List<String> achievements;
  final String contactEmail;
  final String contactPhone;
  final String locationLabel;
  final String profileImageUrl;
  final bool isOpen;
  final bool isActivelyLooking;
  final bool isFeatured;
  final bool boostRequested;
  final RecruitingVisibilityLevel visibilityLevel;
  final RecruitingContactVisibility contactVisibility;
  final RecruitingVisibilitySettingsDraft visibilitySettings;
  final List<RecruitingHighlightDraft> highlights;
  final Map<String, dynamic> statsSummary;
  final String? matchRecordOverride;

  Map<String, dynamic> toJson() {
    return {
      'athlete_id': athleteId,
      'team_id': teamId,
      'graduation_year': graduationYear,
      'school_team': schoolTeam,
      'weight_class': weightClass,
      'height': height,
      'gpa': gpa.isEmpty ? null : gpa,
      'bio': bio,
      'achievements': achievements,
      'contact_email': contactEmail.isEmpty ? null : contactEmail,
      'contact_phone': contactPhone.isEmpty ? null : contactPhone,
      'location_label': locationLabel,
      'profile_image_url': profileImageUrl.isEmpty ? null : profileImageUrl,
      'is_open': isOpen,
      'is_actively_looking': isActivelyLooking,
      'is_featured': isFeatured,
      'boost_requested': boostRequested,
      'visibility_level': recruitingVisibilityLevelToApi(visibilityLevel),
      'contact_visibility': recruitingContactVisibilityToApi(contactVisibility),
      'visibility': visibilitySettings.toJson(),
      'highlights': highlights.map((item) => item.toJson()).toList(growable: false),
      'stats_summary': statsSummary,
      'match_record_override': matchRecordOverride,
    };
  }
}

class RecruitingVisibilitySettingsDraft {
  RecruitingVisibilitySettingsDraft({
    required this.showContactToCoaches,
    required this.showGpa,
    required this.showLocation,
    required this.showProfilePhoto,
    required this.parentVisibilityRequired,
    required this.allowDirectContactRequest,
  });

  final bool showContactToCoaches;
  final bool showGpa;
  final bool showLocation;
  final bool showProfilePhoto;
  final bool parentVisibilityRequired;
  final bool allowDirectContactRequest;

  Map<String, dynamic> toJson() {
    return {
      'show_contact_to_coaches': showContactToCoaches,
      'show_gpa': showGpa,
      'show_location': showLocation,
      'show_profile_photo': showProfilePhoto,
      'parent_visibility_required': parentVisibilityRequired,
      'allow_direct_contact_request': allowDirectContactRequest,
    };
  }
}

class RecruitingHighlightDraft {
  RecruitingHighlightDraft({
    required this.title,
    required this.highlightUrl,
    required this.sortOrder,
  });

  final String title;
  final String highlightUrl;
  final int sortOrder;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'highlight_url': highlightUrl,
      'sort_order': sortOrder,
    };
  }
}

Map<String, dynamic> decodeRecruitingObject(String body) {
  return Map<String, dynamic>.from(jsonDecode(body) as Map);
}

List<Map<String, dynamic>> decodeRecruitingList(String body) {
  return (jsonDecode(body) as List)
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList(growable: false);
}
