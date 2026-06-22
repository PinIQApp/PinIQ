class UserProfile {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final String? phone;
  final int? primaryTeamId;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.primaryTeamId,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      phone: json['phone'] as String?,
      primaryTeamId: json['primary_team_id'] as int?,
    );
  }
}
