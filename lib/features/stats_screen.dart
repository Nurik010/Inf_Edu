import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inf_edu_app/models/user_model.dart';
import 'package:inf_edu_app/models/test_result_model.dart';
import '../../services/firestore_service.dart';
import '../../core/theme/app_theme.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  List<Map<String, dynamic>> _ranking = [];
  Map<String, dynamic>? _userStats;
  List<TestResultModel> _testResults = [];
  final Map<String, String> _topicNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final ranking = await FirestoreService().getGlobalRanking();
    final userId = FirebaseAuth.instance.currentUser?.uid;

    UserModel? userStats;
    if (userId != null) {
      userStats = await FirestoreService().getUser(userId);

      final results = await FirestoreService().getUserTestResults(userId);
      _testResults = results;

      final allTopics = await FirestoreService().getTopics();
      for (final topic in allTopics) {
        _topicNames[topic.id] = topic.title;
      }
    }

    setState(() {
      _ranking = ranking;
      _userStats = userStats?.toJson();
      _isLoading = false;
    });
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

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Статистика и рейтинг')),
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
                  const Text(
                    'Ваши результаты',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        icon: Icons.assignment_turned_in_rounded,
                        label: 'Пройдено тестов',
                        value: '${_userStats?['totalTests'] ?? 0}',
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: Colors.white.withAlpha(60),
                      ),
                      _StatItem(
                        icon: Icons.star_rounded,
                        label: 'Средний балл',
                        value:
                            '${(_userStats?['averageScore'] ?? 0).toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_testResults.isNotEmpty) ...[
              const SizedBox(height: 28),
              const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppTheme.success, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Пройденные тесты',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(_testResults.length, (index) {
                final result = _testResults[index];
                final topicName =
                    _topicNames[result.topicId] ?? 'Неизвестная тема';
                final isPassed = result.percentage >= 70;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: AppTheme.cardDecoration,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isPassed
                              ? AppTheme.success.withAlpha(20)
                              : AppTheme.error.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isPassed
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color:
                              isPassed ? AppTheme.success : AppTheme.error,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topicName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${result.score}/${result.total}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
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
                          gradient: isPassed
                              ? AppTheme.primaryGradient
                              : LinearGradient(
                                  colors: [
                                    AppTheme.textSecondary,
                                    AppTheme.textSecondary,
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${result.percentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 28),
            const Row(
              children: [
                Icon(Icons.emoji_events_rounded,
                    color: AppTheme.primary, size: 24),
                SizedBox(width: 8),
                Text(
                  'Топ пользователей',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_ranking.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: AppTheme.cardDecoration,
                child: const Column(
                  children: [
                    Icon(Icons.emoji_events_outlined,
                        size: 48, color: AppTheme.textSecondary),
                    SizedBox(height: 12),
                    Text(
                      'Нет данных для рейтинга',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(_ranking.length, (index) {
                final user = _ranking[index];
                final isTop3 = index < 3;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: AppTheme.cardDecoration.copyWith(
                    border: isTop3
                        ? Border.all(
                            color: Colors.amber.withAlpha(100),
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: isTop3
                              ? const LinearGradient(
                                  colors: [Colors.amber, Colors.orange],
                                )
                              : null,
                          color: isTop3 ? null : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isTop3 ? Colors.white : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Тестов: ${user['totalTests']}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
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
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${user['averageScore'].toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14,
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

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withAlpha(200),
          ),
        ),
      ],
    );
  }
}
