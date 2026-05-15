import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inf_edu_app/models/test_result_model.dart';
import '../../services/firestore_service.dart';
import '../../core/theme/app_theme.dart';

class CompletedTopicsScreen extends ConsumerStatefulWidget {
  const CompletedTopicsScreen({super.key});

  @override
  ConsumerState<CompletedTopicsScreen> createState() =>
      _CompletedTopicsScreenState();
}

class _CompletedTopicsScreenState
    extends ConsumerState<CompletedTopicsScreen> {
  List<TestResultModel> _results = [];
  final Map<String, String> _topicNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _results = await FirestoreService().getUserTestResults(userId);

    final allTopics = await FirestoreService().getTopics();
    for (final topic in allTopics) {
      _topicNames[topic.id] = topic.title;
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _getEncouragingMessage() {
    final completedCount = _results.where((r) => r.percentage >= 70).length;
    if (completedCount == 0) {
      return 'Начните обучение прямо сейчас!';
    } else if (completedCount < 3) {
      return 'Отличное начало! Так держать!';
    } else if (completedCount < 6) {
      return 'Вы на правильном пути! Продолжайте в том же духе!';
    } else {
      return 'Вы настоящий звёздный ученик!';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
      );
    }

    final completedTopics = _results.where((r) => r.percentage >= 70).toList();
    final totalScore = _results.isEmpty
        ? 0
        : _results.map((r) => r.percentage).reduce((a, b) => a + b) /
            _results.length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Пройденные темы')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.primaryBoxDecoration,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getEncouragingMessage(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${completedTopics.length}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Пройдено тем',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withAlpha(60),
                      ),
                      Column(
                        children: [
                          Text(
                            '${totalScore.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Средний балл',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Row(
              children: [
                Icon(Icons.history_rounded,
                    color: AppTheme.primary, size: 24),
                SizedBox(width: 8),
                Text(
                  'История тестов',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_results.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: AppTheme.cardDecoration,
                child: const Column(
                  children: [
                    Icon(Icons.assignment_outlined,
                        size: 48, color: AppTheme.textSecondary),
                    SizedBox(height: 12),
                    Text(
                      'Пока нет пройденных тестов',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(_results.length, (index) {
                final result = _results[index];
                final isPassed = result.percentage >= 70;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: AppTheme.cardDecoration,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isPassed
                              ? AppTheme.success.withAlpha(25)
                              : AppTheme.warning.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isPassed
                              ? Icons.check_circle_rounded
                              : Icons.auto_awesome_rounded,
                          color:
                              isPassed ? AppTheme.success : AppTheme.warning,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _topicNames[result.topicId] ??
                                  'Неизвестная тема',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${result.score}/${result.total} правильных',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isPassed
                              ? AppTheme.success.withAlpha(25)
                              : AppTheme.warning.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${result.percentage.toInt()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isPassed
                                ? AppTheme.success
                                : AppTheme.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
