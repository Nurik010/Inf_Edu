import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final int age;
  final String email;
  final String? selectedGrade;
  final String? selectedTopic;
  final String? selectedTopicId;
  final String? teacherEmail;
  final DateTime createdAt;
  final int totalTests;
  final double averageScore;

  UserModel({
    required this.id,
    required this.name,
    required this.age,
    required this.email,
    this.selectedGrade,
    this.selectedTopic,
    this.selectedTopicId, 
    this.teacherEmail,
    required this.createdAt,
    this.totalTests = 0,
    this.averageScore = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'email': email,
      'selectedGrade': selectedGrade,
      'selectedTopic': selectedTopic,
      'selectedTopicId': selectedTopicId, 
      'teacherEmail': teacherEmail,
      'createdAt': Timestamp.fromDate(createdAt),
      'totalTests': totalTests,
      'averageScore': averageScore,
    };
  }

  factory UserModel.fromJson(String id, Map<String, dynamic> json) {
    return UserModel(
      id: id,
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      email: json['email'] ?? '',
      selectedGrade: json['selectedGrade'],
      selectedTopic: json['selectedTopic'],
      selectedTopicId: json['selectedTopicId'],
      teacherEmail: json['teacherEmail'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalTests: json['totalTests'] ?? 0,
      averageScore: (json['averageScore'] ?? 0).toDouble(),
    );
  }
}
