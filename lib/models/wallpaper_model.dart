import 'package:cloud_firestore/cloud_firestore.dart';

class WallpaperModel {
  final String id;
  final String url;
  final String title;
  final String uploadedBy;
  final String sourceDevice;
  final DateTime createdAt;

  WallpaperModel({
    required this.id,
    required this.url,
    required this.title,
    required this.uploadedBy,
    required this.sourceDevice,
    required this.createdAt,
  });

  factory WallpaperModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WallpaperModel(
      id: doc.id,
      url: data['url'] ?? '',
      title: data['title'] ?? 'Untitled Wallpaper',
      uploadedBy: data['uploadedBy'] ?? '',
      sourceDevice: data['sourceDevice'] ?? 'Unknown Device',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory WallpaperModel.fromMap(Map<String, dynamic> map, String id) {
    return WallpaperModel(
      id: id,
      url: map['url'] ?? '',
      title: map['title'] ?? 'Untitled Wallpaper',
      uploadedBy: map['uploadedBy'] ?? '',
      sourceDevice: map['sourceDevice'] ?? 'Unknown Device',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] is String
              ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'title': title,
      'uploadedBy': uploadedBy,
      'sourceDevice': sourceDevice,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
