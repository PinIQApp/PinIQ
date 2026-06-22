import 'user_profile.dart';

class TeamMemberModel {
  final int id;
  final String roleLabel;
  final bool isStaff;
  final String status;
  final UserProfile user;

  TeamMemberModel({
    required this.id,
    required this.roleLabel,
    required this.isStaff,
    required this.status,
    required this.user,
  });

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    return TeamMemberModel(
      id: json['id'] as int,
      roleLabel: json['role_label'] as String,
      isStaff: json['is_staff'] as bool,
      status: json['status'] as String,
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  bool get hasPhone => user.phone != null && user.phone!.trim().isNotEmpty;
  bool get hasLikelyValidPhone {
    final phone = user.phone?.trim();
    if (phone == null || phone.isEmpty) return false;
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length == 11 && digits.startsWith('1');
  }
}
