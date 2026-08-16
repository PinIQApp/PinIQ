class AthleteInvitationModel {
  final int id;
  final int teamId;
  final String teamName;
  final int athleteUserId;
  final String athleteFullName;
  final String? athleteEmail;
  final String? parentEmail;
  final String? parentPhone;
  final String relationshipLabel;
  final String status;
  final DateTime expiresAt;
  final DateTime? acceptedAt;
  final DateTime createdAt;

  const AthleteInvitationModel({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.athleteUserId,
    required this.athleteFullName,
    required this.athleteEmail,
    required this.parentEmail,
    required this.parentPhone,
    required this.relationshipLabel,
    required this.status,
    required this.expiresAt,
    required this.acceptedAt,
    required this.createdAt,
  });

  factory AthleteInvitationModel.fromJson(Map<String, dynamic> json) {
    return AthleteInvitationModel(
      id: json['id'] as int,
      teamId: json['team_id'] as int,
      teamName: json['team_name'] as String,
      athleteUserId: json['athlete_user_id'] as int,
      athleteFullName: json['athlete_full_name'] as String,
      athleteEmail: json['athlete_email'] as String?,
      parentEmail: json['parent_email'] as String?,
      parentPhone: json['parent_phone'] as String?,
      relationshipLabel: json['relationship_label'] as String,
      status: json['status'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      acceptedAt: json['accepted_at'] == null
          ? null
          : DateTime.parse(json['accepted_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get parentContact => parentPhone ?? parentEmail ?? 'No contact';
}

class ManagedAthleteProfileModel {
  final int userId;
  final int membershipId;
  final String fullName;
  final String email;
  final String? phone;
  final String? hometown;
  final int? graduationYear;
  final String? weightClass;
  final String? profileImageUrl;
  final String? bio;

  const ManagedAthleteProfileModel({
    required this.userId,
    required this.membershipId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.hometown,
    required this.graduationYear,
    required this.weightClass,
    required this.profileImageUrl,
    required this.bio,
  });

  factory ManagedAthleteProfileModel.fromJson(Map<String, dynamic> json) {
    return ManagedAthleteProfileModel(
      userId: json['user_id'] as int,
      membershipId: json['membership_id'] as int,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      hometown: json['hometown'] as String?,
      graduationYear: json['graduation_year'] as int?,
      weightClass: json['weight_class'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      bio: json['bio'] as String?,
    );
  }
}
