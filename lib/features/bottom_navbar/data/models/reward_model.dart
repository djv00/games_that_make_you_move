import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// TODO: We will use this model as an entity too just for simplicity now
class RewardModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int points;
  final String qrCode;

  const RewardModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.points,
    required this.qrCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'points': points,
      'qrCode': qrCode,
    };
  }

  factory RewardModel.fromMap(Map<String, dynamic> map, String documentId) {
    // 这里不能再用 `as String` 了，因为 Firestore 任何字段都可能是 null
    final rawName = map['name'];
    final rawDesc = map['description'];
    final rawImage = map['imageUrl'];
    final rawQr = map['qrCode'];
    final rawPoints = map['points'];

    // 字符串一律 toString() + 默认值
    final String safeName = rawName == null ? 'Reward' : rawName.toString();
    final String safeDesc = rawDesc == null ? '' : rawDesc.toString();
    final String safeImage = rawImage == null ? '' : rawImage.toString();
    final String safeQr = rawQr == null ? '' : rawQr.toString();

    // 分数可能是 int / double / String / null
    int safePoints;
    if (rawPoints is int) {
      safePoints = rawPoints;
    } else if (rawPoints is num) {
      safePoints = rawPoints.toInt();
    } else if (rawPoints is String) {
      safePoints = int.tryParse(rawPoints) ?? 0;
    } else {
      safePoints = 0;
    }

    return RewardModel(
      id: documentId,
      name: safeName,
      description: safeDesc,
      imageUrl: safeImage,
      points: safePoints,
      qrCode: safeQr,
    );
  }

  @override
  List<Object?> get props => [id];

  RewardModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    int? points,
    String? qrCode,
  }) {
    return RewardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      points: points ?? this.points,
      qrCode: qrCode ?? this.qrCode,
    );
  }
}
