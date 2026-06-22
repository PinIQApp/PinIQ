import 'team_member_model.dart';

class TeamModel {
  final int id;
  final String name;
  final String slug;
  final String joinCode;
  final String schoolName;
  final String? schoolAbbreviation;
  final String mascotName;
  final String primaryColor;
  final String secondaryColor;
  final String accentColor;
  final String surfaceColor;
  final String? logoUrl;
  final String? tagline;
  final List<TeamMemberModel> members;

  TeamModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.joinCode,
    required this.schoolName,
    required this.schoolAbbreviation,
    required this.mascotName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.surfaceColor,
    required this.logoUrl,
    required this.tagline,
    required this.members,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      joinCode: json['join_code'] as String,
      schoolName: json['school_name'] as String,
      schoolAbbreviation: json['school_abbreviation'] as String?,
      mascotName: json['mascot_name'] as String,
      primaryColor: json['primary_color'] as String,
      secondaryColor: json['secondary_color'] as String,
      accentColor: json['accent_color'] as String,
      surfaceColor: json['surface_color'] as String,
      logoUrl: json['logo_url'] as String?,
      tagline: json['tagline'] as String?,
      members: (json['members'] as List<dynamic>? ?? [])
          .map((item) => TeamMemberModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TeamLookupModel {
  final int id;
  final String name;
  final String schoolName;
  final String mascotName;
  final String? division;

  const TeamLookupModel({
    required this.id,
    required this.name,
    required this.schoolName,
    required this.mascotName,
    required this.division,
  });

  String get displayLabel => '$schoolName • $mascotName';

  factory TeamLookupModel.fromJson(Map<String, dynamic> json) {
    return TeamLookupModel(
      id: json['id'] as int,
      name: json['name'] as String,
      schoolName: json['school_name'] as String,
      mascotName: json['mascot_name'] as String,
      division: json['division'] as String?,
    );
  }
}
