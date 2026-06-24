class RecruitingSourceRankingModel {
  const RecruitingSourceRankingModel({
    required this.source,
    this.record,
    this.ranking,
    this.weightClass,
    this.season,
    this.profileUrl,
    this.lastChecked,
  });

  final String source;
  final String? record;
  final String? ranking;
  final String? weightClass;
  final String? season;
  final String? profileUrl;
  final String? lastChecked;

  factory RecruitingSourceRankingModel.fromJson(Map<String, dynamic> json) {
    return RecruitingSourceRankingModel(
      source: json['source'] as String? ?? 'Unknown',
      record: json['record'] as String?,
      ranking: json['ranking'] as String?,
      weightClass: json['weight_class'] as String?,
      season: json['season'] as String?,
      profileUrl: json['profile_url'] as String?,
      lastChecked: json['last_checked'] as String?,
    );
  }
}

class RecruitingSchoolRankingModel {
  const RecruitingSchoolRankingModel({
    required this.source,
    required this.schoolName,
    this.state,
    this.stateRank,
    this.nationalRank,
    this.division,
    this.season,
    this.profileUrl,
    this.lastChecked,
  });

  final String source;
  final String schoolName;
  final String? state;
  final int? stateRank;
  final int? nationalRank;
  final String? division;
  final String? season;
  final String? profileUrl;
  final String? lastChecked;

  factory RecruitingSchoolRankingModel.fromJson(Map<String, dynamic> json) {
    return RecruitingSchoolRankingModel(
      source: json['source'] as String? ?? 'Unknown',
      schoolName: json['school_name'] as String? ?? 'Unknown school',
      state: json['state'] as String?,
      stateRank: json['state_rank'] as int?,
      nationalRank: json['national_rank'] as int?,
      division: json['division'] as String?,
      season: json['season'] as String?,
      profileUrl: json['profile_url'] as String?,
      lastChecked: json['last_checked'] as String?,
    );
  }
}

class RecruitingPinIqRankingModel {
  const RecruitingPinIqRankingModel({
    required this.score,
    required this.tier,
    required this.confidence,
    this.stateRankHint,
    this.nationalRankHint,
  });

  final double score;
  final String tier;
  final String confidence;
  final int? stateRankHint;
  final int? nationalRankHint;

  factory RecruitingPinIqRankingModel.fromJson(Map<String, dynamic> json) {
    return RecruitingPinIqRankingModel(
      score: (json['score'] as num?)?.toDouble() ?? 0,
      tier: json['tier'] as String? ?? 'Developing',
      confidence: json['confidence'] as String? ?? 'low',
      stateRankHint: json['state_rank_hint'] as int?,
      nationalRankHint: json['national_rank_hint'] as int?,
    );
  }
}

class RecruitingSourceScanAuditModel {
  const RecruitingSourceScanAuditModel({
    required this.source,
    required this.url,
    required this.scannedAt,
    required this.success,
    required this.changedFields,
    this.message,
  });

  final String source;
  final String url;
  final DateTime scannedAt;
  final bool success;
  final List<String> changedFields;
  final String? message;

  factory RecruitingSourceScanAuditModel.fromJson(Map<String, dynamic> json) {
    return RecruitingSourceScanAuditModel(
      source: json['source'] as String? ?? 'Unknown',
      url: json['url'] as String? ?? '',
      scannedAt: DateTime.parse(json['scanned_at'] as String),
      success: json['success'] as bool? ?? false,
      changedFields: (json['changed_fields'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      message: json['message'] as String?,
    );
  }
}

class RecruitingAthleteModel {
  const RecruitingAthleteModel({
    required this.athleteId,
    required this.profileId,
    required this.athleteName,
    required this.graduationYear,
    required this.weightClass,
    required this.isOpen,
    required this.isActivelyLooking,
    required this.isFeatured,
    required this.record,
    required this.sourceRankings,
    required this.schoolRankings,
    required this.sourceScanAudit,
    required this.achievements,
    required this.highlightCount,
    required this.updatedAt,
    required this.trendingScore,
    this.schoolTeam,
    this.locationLabel,
    this.height,
    this.profileImageUrl,
    this.trendLabel,
    this.winPercentage,
    this.bonusPointRate,
    this.pinIqRanking,
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
  final String record;
  final String? trendLabel;
  final double? winPercentage;
  final double? bonusPointRate;
  final RecruitingPinIqRankingModel? pinIqRanking;
  final List<RecruitingSourceRankingModel> sourceRankings;
  final List<RecruitingSchoolRankingModel> schoolRankings;
  final List<RecruitingSourceScanAuditModel> sourceScanAudit;
  final List<String> achievements;
  final int highlightCount;
  final DateTime updatedAt;
  final double trendingScore;

  factory RecruitingAthleteModel.fromJson(Map<String, dynamic> json) {
    return RecruitingAthleteModel(
      athleteId: json['athlete_id'] as int,
      profileId: json['profile_id'] as int,
      athleteName: json['athlete_name'] as String? ?? 'Unknown athlete',
      schoolTeam: json['school_team'] as String?,
      locationLabel: json['location_label'] as String?,
      graduationYear: json['graduation_year'] as int? ?? 0,
      weightClass: json['weight_class'] as String? ?? '-',
      height: json['height'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      isOpen: json['is_open'] as bool? ?? false,
      isActivelyLooking: json['is_actively_looking'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      record: json['record'] as String? ?? '0-0',
      trendLabel: json['trend_label'] as String?,
      winPercentage: (json['win_percentage'] as num?)?.toDouble(),
      bonusPointRate: (json['bonus_point_rate'] as num?)?.toDouble(),
      pinIqRanking: json['piniq_ranking'] == null
          ? null
          : RecruitingPinIqRankingModel.fromJson(
              json['piniq_ranking'] as Map<String, dynamic>),
      sourceRankings: (json['source_rankings'] as List<dynamic>? ?? const [])
          .map((item) => RecruitingSourceRankingModel.fromJson(
              item as Map<String, dynamic>))
          .toList(),
      schoolRankings: (json['school_rankings'] as List<dynamic>? ?? const [])
          .map((item) => RecruitingSchoolRankingModel.fromJson(
              item as Map<String, dynamic>))
          .toList(),
      sourceScanAudit: (json['source_scan_audit'] as List<dynamic>? ?? const [])
          .map((item) => RecruitingSourceScanAuditModel.fromJson(
              item as Map<String, dynamic>))
          .toList(),
      achievements: (json['achievements'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      highlightCount: json['highlight_count'] as int? ?? 0,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      trendingScore: (json['trending_score'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RecruitingSourceLinkModel {
  const RecruitingSourceLinkModel({
    required this.source,
    required this.url,
  });

  final String source;
  final String url;

  Map<String, dynamic> toJson() => {'source': source, 'url': url};

  factory RecruitingSourceLinkModel.fromJson(Map<String, dynamic> json) {
    return RecruitingSourceLinkModel(
      source: json['source'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }
}

class RecruitingSourceScanResultModel {
  const RecruitingSourceScanResultModel({
    required this.source,
    required this.url,
    required this.success,
    required this.sourceRankings,
    required this.schoolRankings,
    this.message,
  });

  final String source;
  final String url;
  final bool success;
  final String? message;
  final List<RecruitingSourceRankingModel> sourceRankings;
  final List<RecruitingSchoolRankingModel> schoolRankings;

  factory RecruitingSourceScanResultModel.fromJson(Map<String, dynamic> json) {
    return RecruitingSourceScanResultModel(
      source: json['source'] as String? ?? 'Unknown',
      url: json['url'] as String? ?? '',
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      sourceRankings: (json['source_rankings'] as List<dynamic>? ?? const [])
          .map((item) => RecruitingSourceRankingModel.fromJson(
              item as Map<String, dynamic>))
          .toList(),
      schoolRankings: (json['school_rankings'] as List<dynamic>? ?? const [])
          .map((item) => RecruitingSchoolRankingModel.fromJson(
              item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RecruitingSourceScanResponseModel {
  const RecruitingSourceScanResponseModel({
    required this.updatedProfile,
    required this.sourceRankings,
    required this.schoolRankings,
    required this.results,
  });

  final bool updatedProfile;
  final List<RecruitingSourceRankingModel> sourceRankings;
  final List<RecruitingSchoolRankingModel> schoolRankings;
  final List<RecruitingSourceScanResultModel> results;

  factory RecruitingSourceScanResponseModel.fromJson(
      Map<String, dynamic> json) {
    return RecruitingSourceScanResponseModel(
      updatedProfile: json['updated_profile'] as bool? ?? false,
      sourceRankings: (json['source_rankings'] as List<dynamic>? ?? const [])
          .map((item) => RecruitingSourceRankingModel.fromJson(
              item as Map<String, dynamic>))
          .toList(),
      schoolRankings: (json['school_rankings'] as List<dynamic>? ?? const [])
          .map((item) => RecruitingSchoolRankingModel.fromJson(
              item as Map<String, dynamic>))
          .toList(),
      results: (json['results'] as List<dynamic>? ?? const [])
          .map((item) => RecruitingSourceScanResultModel.fromJson(
              item as Map<String, dynamic>))
          .toList(),
    );
  }
}
