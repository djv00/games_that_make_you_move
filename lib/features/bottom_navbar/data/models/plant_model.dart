import 'package:cloud_firestore/cloud_firestore.dart';

class PlantModel {
  final int level;          // 等级
  final int progress;       // 当前进度 0~100
  final Timestamp? lastWateredAt;

  PlantModel({
    required this.level,
    required this.progress,
    this.lastWateredAt,
  });

  factory PlantModel.fromMap(Map<String, dynamic> map) {
    return PlantModel(
      level: (map['level'] ?? 1) as int,
      progress: (map['progress'] ?? 0) as int,
      lastWateredAt: map['lastWateredAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'progress': progress,
      'lastWateredAt': lastWateredAt,
    };
  }

  PlantModel copyWith({
    int? level,
    int? progress,
    Timestamp? lastWateredAt,
  }) {
    return PlantModel(
      level: level ?? this.level,
      progress: progress ?? this.progress,
      lastWateredAt: lastWateredAt ?? this.lastWateredAt,
    );
  }
}
