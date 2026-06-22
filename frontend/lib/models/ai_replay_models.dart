class AiReplayClipModel {
  const AiReplayClipModel({
    required this.id,
    required this.timecode,
    required this.label,
    required this.note,
    required this.lane,
  });

  final String id;
  final String timecode;
  final String label;
  final String note;
  final String lane;

  AiReplayClipModel copyWith({
    String? id,
    String? timecode,
    String? label,
    String? note,
    String? lane,
  }) {
    return AiReplayClipModel(
      id: id ?? this.id,
      timecode: timecode ?? this.timecode,
      label: label ?? this.label,
      note: note ?? this.note,
      lane: lane ?? this.lane,
    );
  }
}

class AiReplayFilmFindingModel {
  const AiReplayFilmFindingModel({
    required this.title,
    required this.right,
    required this.wrong,
    required this.fix,
    required this.drill,
    required this.confidence,
    this.timecode,
  });

  final String title;
  final String right;
  final String wrong;
  final String fix;
  final String drill;
  final double confidence;
  final String? timecode;

  factory AiReplayFilmFindingModel.fromJson(Map<String, dynamic> json) {
    return AiReplayFilmFindingModel(
      title: json['title'] as String? ?? 'Film-study finding',
      right: json['right'] as String? ?? 'Positive position was visible.',
      wrong: json['wrong'] as String? ?? 'Technical correction needed.',
      fix: json['fix'] as String? ?? 'Review and drill the corrected position.',
      drill: json['drill'] as String? ?? 'Coach-selected situational reps.',
      confidence: (json['confidence'] as num? ?? 0.5).toDouble(),
      timecode: json['timecode'] as String?,
    );
  }
}

class AiReplayFilmStudyModel {
  const AiReplayFilmStudyModel({
    required this.filmSource,
    required this.status,
    required this.analysisMode,
    required this.coachSummary,
    required this.athleteActionPlan,
    required this.parentSummary,
    required this.findings,
    required this.frameCount,
    this.mediaUrl,
  });

  final String filmSource;
  final String status;
  final String analysisMode;
  final String coachSummary;
  final String athleteActionPlan;
  final String parentSummary;
  final List<AiReplayFilmFindingModel> findings;
  final int frameCount;
  final String? mediaUrl;

  factory AiReplayFilmStudyModel.fromJson(Map<String, dynamic> json) {
    return AiReplayFilmStudyModel(
      filmSource: json['film_source'] as String? ?? '',
      status: json['status'] as String? ?? 'ready',
      analysisMode: json['analysis_mode'] as String? ?? 'beta_fallback',
      coachSummary: json['coach_summary'] as String? ?? '',
      athleteActionPlan: json['athlete_action_plan'] as String? ?? '',
      parentSummary: json['parent_summary'] as String? ?? '',
      findings: (json['findings'] as List<dynamic>? ?? const [])
          .map((item) =>
              AiReplayFilmFindingModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      frameCount: json['frame_count'] as int? ?? 0,
      mediaUrl: json['media_url'] as String?,
    );
  }
}

class AiReplayReviewModel {
  const AiReplayReviewModel({
    required this.id,
    required this.title,
    required this.eventLabel,
    required this.athleteName,
    required this.opponentName,
    required this.weightClass,
    required this.filmSource,
    required this.status,
    required this.focus,
    required this.coachSummary,
    required this.athleteActionPlan,
    required this.parentSummary,
    required this.clips,
    required this.updatedAtLabel,
  });

  final String id;
  final String title;
  final String eventLabel;
  final String athleteName;
  final String opponentName;
  final String weightClass;
  final String filmSource;
  final String status;
  final String focus;
  final String coachSummary;
  final String athleteActionPlan;
  final String parentSummary;
  final List<AiReplayClipModel> clips;
  final String updatedAtLabel;

  AiReplayReviewModel copyWith({
    String? id,
    String? title,
    String? eventLabel,
    String? athleteName,
    String? opponentName,
    String? weightClass,
    String? filmSource,
    String? status,
    String? focus,
    String? coachSummary,
    String? athleteActionPlan,
    String? parentSummary,
    List<AiReplayClipModel>? clips,
    String? updatedAtLabel,
  }) {
    return AiReplayReviewModel(
      id: id ?? this.id,
      title: title ?? this.title,
      eventLabel: eventLabel ?? this.eventLabel,
      athleteName: athleteName ?? this.athleteName,
      opponentName: opponentName ?? this.opponentName,
      weightClass: weightClass ?? this.weightClass,
      filmSource: filmSource ?? this.filmSource,
      status: status ?? this.status,
      focus: focus ?? this.focus,
      coachSummary: coachSummary ?? this.coachSummary,
      athleteActionPlan: athleteActionPlan ?? this.athleteActionPlan,
      parentSummary: parentSummary ?? this.parentSummary,
      clips: clips ?? this.clips,
      updatedAtLabel: updatedAtLabel ?? this.updatedAtLabel,
    );
  }
}

List<AiReplayReviewModel> seedAiReplayReviews() {
  return const [
    AiReplayReviewModel(
      id: 'avery-bluegrass-quarterfinal',
      title: 'Quarterfinal vs. North Oldham',
      eventLabel: 'Bluegrass Spring Open',
      athleteName: 'Avery Hall',
      opponentName: 'North Oldham',
      weightClass: '132 lb',
      filmSource: 'coach-uploaded-bluegrass-qf.mp4',
      status: 'Coach review',
      focus: 'Finish the first clean entry before the hips square on the edge.',
      coachSummary:
          'Avery created good neutral looks, but the best single-leg entries stalled once position flattened near the edge.',
      athleteActionPlan:
          'Rehearse 3 immediate finish choices from the left-side single and reset motion after stalled hand fighting.',
      parentSummary:
          'Strong effort and clear scoring chances. The next practice focus is finishing clean attacks under pressure.',
      clips: [
        AiReplayClipModel(
          id: 'clip-1',
          timecode: '0:44',
          label: 'Single-leg entry',
          note:
              'Best attack of period one. Angle is good before the edge kills the finish.',
          lane: 'Neutral control',
        ),
        AiReplayClipModel(
          id: 'clip-2',
          timecode: '2:08',
          label: 'Finish stalls',
          note:
              'Hips square too early. Needs an immediate shelf or cut corner.',
          lane: 'Finishes + conversions',
        ),
        AiReplayClipModel(
          id: 'clip-3',
          timecode: '5:31',
          label: 'Late scramble',
          note:
              'Good fight late, but pace drops after extended scramble exchange.',
          lane: 'Defense + pace',
        ),
      ],
      updatedAtLabel: 'Updated 12 min ago',
    ),
    AiReplayReviewModel(
      id: 'mila-regional-semifinal',
      title: 'Semifinal vs. South Laurel',
      eventLabel: 'Regional Championship',
      athleteName: 'Mila Carter',
      opponentName: 'South Laurel',
      weightClass: '126 lb',
      filmSource: 'regional-semifinal-clip-set.mov',
      status: 'Ready to share',
      focus:
          'Protect lead changes by getting out of long upper-body ties faster.',
      coachSummary:
          'Mila controlled most neutral exchanges early, but extended upper-body ties created two unnecessary danger spots.',
      athleteActionPlan:
          'Clear ties faster, keep feet underneath the hips, and go back to the snap-single sequence that scored first.',
      parentSummary:
          'The match was competitive and showed strong control early. Coaches are cleaning up a few late-position details.',
      clips: [
        AiReplayClipModel(
          id: 'clip-4',
          timecode: '1:12',
          label: 'Snap-single score',
          note:
              'Best repeatable scoring sequence. Good timing and level change.',
          lane: 'Finishes + conversions',
        ),
        AiReplayClipModel(
          id: 'clip-5',
          timecode: '4:02',
          label: 'Upper-body stall',
          note:
              'Need a faster exit instead of hanging in a chest-to-chest tie.',
          lane: 'Defense + pace',
        ),
      ],
      updatedAtLabel: 'Updated yesterday',
    ),
  ];
}
