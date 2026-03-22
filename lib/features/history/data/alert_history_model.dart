class AlertHistoryModel {
  final int id;
  final String triggerType;
  final String? latitude;
  final String? longitude;
  final String? frontPhotoUrl;
  final String? rearPhotoUrl;
  final String status;
  final bool isTest;
  final String createdAt;

  AlertHistoryModel({
    required this.id,
    required this.triggerType,
    this.latitude,
    this.longitude,
    this.frontPhotoUrl,
    this.rearPhotoUrl,
    required this.status,
    required this.isTest,
    required this.createdAt,
  });

  factory AlertHistoryModel.fromJson(Map<String, dynamic> json) {
    return AlertHistoryModel(
      id: json['id'],
      triggerType: json['trigger_type'],
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      frontPhotoUrl: json['front_photo_url'],
      rearPhotoUrl: json['rear_photo_url'],
      status: json['status'],
      isTest: json['is_test'] ?? false,
      createdAt: json['created_at'],
    );
  }

  // Computed helpers used by the UI

  bool get hasLocation => latitude != null && longitude != null;

  String get mapsUrl => 'https://maps.google.com/?q=$latitude,$longitude';

  String get triggerLabel {
    switch (triggerType) {
      case 'volume_button':
        return 'Volume Button';
      case 'shake':
        return 'Shake';
      case 'manual':
        return 'Manual';
      default:
        return triggerType;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'sent':
        return 'Sent';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }

  // Parse ISO timestamp into readable format
  String get formattedDate {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final date =
          '${dt.year}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.day.toString().padLeft(2, '0')}';
      final time =
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
      return '$date at $time';
    } catch (_) {
      return createdAt;
    }
  }
}
