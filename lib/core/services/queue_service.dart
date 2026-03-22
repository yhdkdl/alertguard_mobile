import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../database/local_database.dart';

class PendingAlert {
  final int? id;
  final String triggerType;
  final double? latitude;
  final double? longitude;
  final String? frontPhotoPath;
  final String? rearPhotoPath;
  final bool isTest;
  final String createdAt;
  final int retryCount;
  final String idempotencyKey;

  PendingAlert({
    this.id,
    required this.triggerType,
    this.latitude,
    this.longitude,
    this.frontPhotoPath,
    this.rearPhotoPath,
    required this.isTest,
    required this.createdAt,
    this.retryCount = 0,
    required this.idempotencyKey,
  });

  Map<String, dynamic> toMap() {
    return {
      'trigger_type': triggerType,
      'latitude': latitude,
      'longitude': longitude,
      'front_photo_path': frontPhotoPath,
      'rear_photo_path': rearPhotoPath,
      'is_test': isTest ? 1 : 0,
      'created_at': createdAt,
      'retry_count': retryCount,
      'idempotency_key': idempotencyKey,
    };
  }

  factory PendingAlert.fromMap(Map<String, dynamic> map) {
    return PendingAlert(
      id: map['id'],
      triggerType: map['trigger_type'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      frontPhotoPath: map['front_photo_path'],
      rearPhotoPath: map['rear_photo_path'],
      isTest: map['is_test'] == 1,
      createdAt: map['created_at'],
      retryCount: map['retry_count'] ?? 0,
      idempotencyKey: map['idempotency_key'] ?? '',
    );
  }
}

class QueueService {
  static const int maxRetries = 5;

  static Future<int> enqueue({
    required String triggerType,
    double? latitude,
    double? longitude,
    String? frontPhotoPath,
    String? rearPhotoPath,
    bool isTest = false,
    required String idempotencyKey,
  }) async {
    final db = await LocalDatabase.instance;

    final alert = PendingAlert(
      triggerType: triggerType,
      latitude: latitude,
      longitude: longitude,
      frontPhotoPath: frontPhotoPath,
      rearPhotoPath: rearPhotoPath,
      isTest: isTest,
      createdAt: DateTime.now().toUtc().toIso8601String(),
      idempotencyKey: idempotencyKey,
    );

    final id = await db.insert('pending_alerts', alert.toMap());
    print('[Queue] Alert enqueued — id: $id key: $idempotencyKey');
    return id;
  }

  static Future<List<PendingAlert>> getPendingAlerts() async {
    final db = await LocalDatabase.instance;
    final rows = await db.query('pending_alerts', orderBy: 'created_at ASC');
    return rows.map(PendingAlert.fromMap).toList();
  }

  static Future<void> dequeue(int id) async {
    final db = await LocalDatabase.instance;
    final deleted = await db.delete(
      'pending_alerts',
      where: 'id = ?',
      whereArgs: [id],
    );
    print('[Queue] Alert $id dequeued — rows deleted: $deleted');
  }

  static Future<void> incrementRetry(int id) async {
    final db = await LocalDatabase.instance;
    await db.rawUpdate(
      'UPDATE pending_alerts '
      'SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  static Future<void> pruneExhausted() async {
    final db = await LocalDatabase.instance;
    final deleted = await db.delete(
      'pending_alerts',
      where: 'retry_count >= ?',
      whereArgs: [maxRetries],
    );
    if (deleted > 0) {
      print('[Queue] Pruned $deleted exhausted alerts');
    }
  }

  static Future<int> getPendingCount() async {
    final db = await LocalDatabase.instance;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM pending_alerts',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static bool photoExists(String? path) {
    if (path == null) return false;
    return File(path).existsSync();
  }
}
