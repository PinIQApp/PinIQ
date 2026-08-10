class TeamWorkoutModel {
  final int id;
  final String title;
  final DateTime? practiceDate;
  final String? focus;
  final int totalDurationMinutes;
  final int totalBlockCount;

  const TeamWorkoutModel({
    required this.id,
    required this.title,
    required this.practiceDate,
    required this.focus,
    required this.totalDurationMinutes,
    required this.totalBlockCount,
  });

  factory TeamWorkoutModel.fromJson(Map<String, dynamic> json) {
    return TeamWorkoutModel(
      id: json['id'] as int,
      title: json['title'] as String,
      practiceDate: json['practice_date'] == null
          ? null
          : DateTime.parse(json['practice_date'] as String),
      focus: json['focus'] as String?,
      totalDurationMinutes: json['total_duration_minutes'] as int,
      totalBlockCount: json['total_block_count'] as int,
    );
  }
}

class TeamWorkoutDetailModel {
  final int id;
  final String title;
  final String? description;
  final String? focus;
  final DateTime? practiceDate;
  final String? notes;
  final int totalDurationMinutes;

  const TeamWorkoutDetailModel({
    required this.id,
    required this.title,
    required this.description,
    required this.focus,
    required this.practiceDate,
    required this.notes,
    required this.totalDurationMinutes,
  });

  factory TeamWorkoutDetailModel.fromJson(Map<String, dynamic> json) {
    return TeamWorkoutDetailModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      focus: json['focus'] as String?,
      practiceDate: json['practice_date'] == null
          ? null
          : DateTime.parse(json['practice_date'] as String),
      notes: json['notes'] as String?,
      totalDurationMinutes: json['total_duration_minutes'] as int,
    );
  }
}
