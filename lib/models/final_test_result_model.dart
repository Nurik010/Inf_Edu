import 'package:cloud_firestore/cloud_firestore.dart';

class FinalTestResultModel {
  final String id;
  final String userId;
  final String topicId;
  final int score;
  final int total;
  final double percentage;
  final DateTime timestamp;
  final int timeSpentSeconds;

  FinalTestResultModel({
    required this.id,
    required this.userId,
    required this.topicId,
    required this.score,
    required this.total,
    required this.percentage,
    required this.timestamp,
    required this.timeSpentSeconds,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'topicId': topicId,
      'score': score,
      'total': total,
      'percentage': percentage,
      'timestamp': Timestamp.fromDate(timestamp),
      'timeSpentSeconds': timeSpentSeconds,
    };
  }

  factory FinalTestResultModel.fromJson(String id, Map<String, dynamic> json) {
    return FinalTestResultModel(
      id: id,
      userId: json['userId'] ?? '',
      topicId: json['topicId'] ?? '',
      score: json['score'] ?? 0,
      total: json['total'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeSpentSeconds: json['timeSpentSeconds'] ?? 0,
    );
  }
}
