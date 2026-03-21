class ContactModel {
  final int id;
  final String name;
  final String phoneNumber;
  final String relationship;
  final String? telegramId;
  final bool telegramVerified;
  final String inviteLink;
  final String createdAt;

  ContactModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.telegramId,
    required this.telegramVerified,
    required this.inviteLink,
    required this.createdAt,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phone_number'],
      relationship: json['relationship'],
      telegramId: json['telegram_id'],
      telegramVerified: json['telegram_verified'] ?? false,
      inviteLink: json['invite_link'] ?? '',
      createdAt: json['created_at'],
    );
  }
}
