import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceModel {
  final String deviceId;
  final String deviceName;
  final String platform; // "macos", "android", "ios"
  final String fcmToken;
  final DateTime lastActive;
  final bool autoApply;

  DeviceModel({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.fcmToken,
    required this.lastActive,
    this.autoApply = true,
  });

  factory DeviceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DeviceModel(
      deviceId: doc.id,
      deviceName: data['deviceName'] ?? 'Unknown Device',
      platform: data['platform'] ?? 'unknown',
      fcmToken: data['fcmToken'] ?? '',
      lastActive: (data['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
      autoApply: data['autoApply'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceName': deviceName,
      'platform': platform,
      'fcmToken': fcmToken,
      'lastActive': Timestamp.fromDate(lastActive),
      'autoApply': autoApply,
    };
  }
}
