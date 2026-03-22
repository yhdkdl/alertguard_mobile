class ProfileModel {
  final int id;
  final String email;
  final String fullName;
  final String? telegramId;
  final bool telegramVerified;
  final String? inviteLink;
  final String createdAt;

  ProfileModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.telegramId,
    required this.telegramVerified,
    this.inviteLink,
    required this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      telegramId: json['telegram_id'],
      telegramVerified: json['telegram_verified'] ?? false,
      inviteLink: json['invite_link'],
      createdAt: json['created_at'],
    );
  }
}
