import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// TODO: We will use this model as an entity too just for simplicity now
class ExchangeHistoryModel extends Equatable {
  final String id;
  final String title;
  /// 存成字符串给UI用，比如 '2025-10-30 12:00'
  final String date;
  final int points;

  const ExchangeHistoryModel({
    required this.id,
    required this.title,
    required this.date,
    required this.points,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'points': points,
    };
  }

  factory ExchangeHistoryModel.fromMap(
      Map<String, dynamic> map,
      String documentId,
      ) {
    // title 可能是 null
    final rawTitle = map['title'];
    final String safeTitle = rawTitle == null ? 'Exchange' : rawTitle.toString();

    // date 可能是 String / Timestamp / null
    String safeDate = '';
    final rawDate = map['date'];
    if (rawDate is String) {
      safeDate = rawDate;
    } else if (rawDate is Timestamp) {
      safeDate = rawDate.toDate().toIso8601String();
    } else {
      safeDate = '';
    }

    // points 可能是 int / double / null
    final rawPoints = map['points'];
    int safePoints;
    if (rawPoints is int) {
      safePoints = rawPoints;
    } else if (rawPoints is num) {
      safePoints = rawPoints.toInt();
    } else {
      safePoints = 0;
    }

    return ExchangeHistoryModel(
      id: documentId,
      title: safeTitle,
      date: safeDate,
      points: safePoints,
    );
  }

  @override
  List<Object?> get props => [id];
}
