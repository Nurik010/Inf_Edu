import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:inf_edu_app/models/test_result_model.dart';
import 'package:inf_edu_app/models/final_test_result_model.dart';
import 'package:inf_edu_app/models/topic_model.dart';
import 'package:inf_edu_app/data/default_questions.dart';
import 'package:inf_edu_app/models/question_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User operations
  Future<void> saveUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toJson());
  }

  Future<UserModel?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return UserModel.fromJson(doc.id, doc.data()!);
    }
    return null;
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  // Topics
  Future<List<TopicModel>> getTopics({String? grade}) async {
    try {
      Query query = _firestore.collection('topics');
      if (grade != null && grade.isNotEmpty) {
        query = query.where('grade', isEqualTo: grade);
      }
      final snapshot = await query.orderBy('order').get();
      
      return snapshot.docs
          .map(
            (doc) => TopicModel.fromJson(doc.id, doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('Ошибка в getTopics: $e');
      return [];
    }
  }

  // Questions
  Future<List<QuestionModel>> getQuestions(String topicId) async {
    try {
      final snapshot = await _firestore
          .collection('topics')
          .doc(topicId)
          .collection('questions')
          .get();

      if (snapshot.docs.isEmpty) {
        print('Вопросов в Firestore нет, использую fallback');
        return DefaultQuestions.getQuestions(topicId);
      }

      return snapshot.docs
          .map((doc) => QuestionModel.fromJson(doc.id, doc.data() as Map<String, dynamic>))
          .toList()
        ..shuffle();
    } catch (e) {
      print('Ошибка загрузки вопросов: $e');
      return DefaultQuestions.getQuestions(topicId);
    }
  }

  // Final questions
  Future<List<QuestionModel>> getFinalQuestions(String topicId) async {
    try {
      final snapshot = await _firestore
          .collection('topics')
          .doc(topicId)
          .collection('finalQuestions')
          .get();

      if (snapshot.docs.isEmpty) {
        print('Финальных вопросов в Firestore нет');
        return [];
      }

      return snapshot.docs
          .map((doc) => QuestionModel.fromJson(doc.id, doc.data() as Map<String, dynamic>))
          .toList()
        ..shuffle();
    } catch (e) {
      print('Ошибка загрузки финальных вопросов: $e');
      return [];
    }
  }

  Future<void> saveFinalTestResult(FinalTestResultModel result) async {
    await _firestore.collection('final_test_results').add(result.toJson());
    await _updateUserStats(result.userId);
  }

  // Test results
  Future<void> saveTestResult(TestResultModel result) async {
    await _firestore.collection('test_results').add(result.toJson());
    await _updateUserStats(result.userId);
  }

  Future<List<TestResultModel>> getUserTestResults(String userId) async {
    final snapshot = await _firestore
        .collection('test_results')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => TestResultModel.fromJson(doc.id, doc.data()))
        .toList();
  }

  Future<List<FinalTestResultModel>> getUserFinalTestResults(String userId) async {
    final snapshot = await _firestore
        .collection('final_test_results')
        .where('userId', isEqualTo: userId)
        .get();
    final results = snapshot.docs
        .map((doc) => FinalTestResultModel.fromJson(doc.id, doc.data()))
        .toList();
    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return results;
  }

  Future<List<TestResultModel>> getTopicTestResults(
    String userId,
    String topicId,
  ) async {
    final snapshot = await _firestore
        .collection('test_results')
        .where('userId', isEqualTo: userId)
        .where('topicId', isEqualTo: topicId)
        .get();
    return snapshot.docs
        .map((doc) => TestResultModel.fromJson(doc.id, doc.data()))
        .toList();
  }

  // Update user statistics
  Future<void> _updateUserStats(String userId) async {
    final results = await getUserTestResults(userId);
    final totalTests = results.length;
    final averageScore = results.isEmpty
        ? 0
        : results.map((r) => r.percentage).reduce((a, b) => a + b) / totalTests;

    await updateUser(userId, {
      'totalTests': totalTests,
      'averageScore': averageScore,
    });
  }

  // Global statistics
  Future<List<Map<String, dynamic>>> getGlobalRanking() async {
    final snapshot = await _firestore
        .collection('users')
        .orderBy('averageScore', descending: true)
        .limit(10)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'name': data['name'] ?? 'User',
        'averageScore': data['averageScore'] ?? 0,
        'totalTests': data['totalTests'] ?? 0,
      };
    }).toList();
  }

  // Completed topics
  Future<List<String>> getCompletedTopicIds(String userId) async {
    final results = await getUserTestResults(userId);
    final completedTopics = <String>{};
    for (final result in results) {
      if (result.percentage >= 70) {
        completedTopics.add(result.topicId);
      }
    }
    return completedTopics.toList();
  }

  Future<List<TopicModel>> getTopicsByGrade(String grade) async {
    try {
      print('getTopicsByGrade вызван с grade = "$grade"');
      
      final snapshot = await _firestore
          .collection('topics')
          .where('grade', isEqualTo: grade)
          .get();
      
      print('Найдено документов: ${snapshot.docs.length}');
      
      final topics = snapshot.docs.map((doc) {
        print('Обработка документа ${doc.id}: grade="${doc.data()['grade']}"');
        return TopicModel.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      
      print('Возвращаем ${topics.length} тем');
      return topics;
    } catch (e) {
      print('Ошибка в getTopicsByGrade: $e');
      return [];
    }
  }

  Future<TopicModel?> getTopic(String topicId) async {
    try {
      final doc = await _firestore.collection('topics').doc(topicId).get();
      if (doc.exists) {
        return TopicModel.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Ошибка получения темы: $e');
      return null;
    }
  }
}
