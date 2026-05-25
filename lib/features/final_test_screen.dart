import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:inf_edu_app/models/question_model.dart';
import 'package:inf_edu_app/models/final_test_result_model.dart';
import 'package:inf_edu_app/features/widgets/question_widget.dart';
import '../../app/providers.dart';
import '../../services/firestore_service.dart';
import '../../core/theme/app_theme.dart';

class FinalTestScreen extends ConsumerStatefulWidget {
  const FinalTestScreen({super.key});

  @override
  ConsumerState<FinalTestScreen> createState() => _FinalTestScreenState();
}

class _FinalTestScreenState extends ConsumerState<FinalTestScreen> {
  int _currentIndex = 0;
  List<dynamic> _userAnswers = [];
  List<QuestionModel> _questions = [];
  bool _isLoading = true;
  bool _testCompleted = false;
  String? _error;
  String? _currentTopicId;

  int _timeSeconds = 0;
  int _totalTimeSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String? topicId = ref.read(selectedTopicIdProvider);

      if (topicId == null || topicId.isEmpty) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          final userData = await FirestoreService().getUser(userId);
          topicId = userData?.selectedTopicId;
          if (topicId != null) {
            ref.read(selectedTopicIdProvider.notifier).state = topicId;
          }
        }
      }

      if (topicId == null || topicId.isEmpty) {
        setState(() {
          _error = 'Сначала выберите тему на главном экране';
          _isLoading = false;
        });
        return;
      }

      _currentTopicId = topicId;
      final questions = await FirestoreService().getFinalQuestions(topicId);

      if (questions.isEmpty) {
        setState(() {
          _error = 'Нет финальных вопросов для этой темы';
          _isLoading = false;
        });
        return;
      }

      _totalTimeSeconds = questions.length * 60;
      _timeSeconds = _totalTimeSeconds;

      setState(() {
        _questions = questions;
        _userAnswers = List.filled(questions.length, null);
        _isLoading = false;
      });

      _startTimer();
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки: $e';
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeSeconds > 0) {
          _timeSeconds--;
        } else {
          timer.cancel();
          _finishTest();
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _answerQuestion(dynamic answer) {
    setState(() {
      _userAnswers[_currentIndex] = answer;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _finishTest();
    }
  }

  bool _isAnswerCorrect(int index) {
    final question = _questions[index];
    final answer = _userAnswers[index];

    if (answer == null) return false;

    switch (question.type) {
      case QuestionType.multipleChoice:
        return answer == question.correctIndex;
      case QuestionType.codeOrdering:
        final order = answer as List<int>;
        if (order.length != question.correctOrder!.length) return false;
        for (int i = 0; i < order.length; i++) {
          if (order[i] != question.correctOrder![i]) return false;
        }
        return true;
      case QuestionType.matching:
        final matches = answer as Map<String, String>;
        if (matches.length != question.pairs!.length) return false;
        for (final entry in matches.entries) {
          if (question.pairs![entry.value] != entry.key) return false;
        }
        return true;
    }
  }

  Future<void> _finishTest() async {
    _timer?.cancel();

    int correctCount = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_isAnswerCorrect(i)) correctCount++;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    String topicId =
        _currentTopicId ?? ref.read(selectedTopicIdProvider) ?? '';
    if (topicId.isEmpty) {
      final userData = await FirestoreService().getUser(userId);
      topicId = userData?.selectedTopicId ?? '';
    }

    if (topicId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: тема не выбрана')),
      );
      return;
    }

    final percentage = (correctCount / _questions.length) * 100;
    final timeSpent = _totalTimeSeconds - _timeSeconds;

    final topic = await FirestoreService().getTopic(topicId);
    final topicName = topic?.title ?? 'Неизвестная тема';

    final result = FinalTestResultModel(
      id: '',
      userId: userId,
      topicId: topicId,
      score: correctCount,
      total: _questions.length,
      percentage: percentage,
      timestamp: DateTime.now(),
      timeSpentSeconds: timeSpent,
    );

    await FirestoreService().saveFinalTestResult(result);
    ref.read(refreshUserDataProvider.notifier).state =
        !ref.read(refreshUserDataProvider.notifier).state;

    if (!mounted) return;

    final userData = await FirestoreService().getUser(userId);
    final teacherEmail = userData?.teacherEmail ?? '';

    setState(() => _testCompleted = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          'Финальный тест завершён!',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: correctCount >= _questions.length * 0.7
                    ? AppTheme.success.withAlpha(25)
                    : AppTheme.warning.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                correctCount >= _questions.length * 0.7
                    ? Icons.celebration_rounded
                    : Icons.auto_awesome_rounded,
                size: 48,
                color: correctCount >= _questions.length * 0.7
                    ? AppTheme.success
                    : AppTheme.warning,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Результат: $correctCount из ${_questions.length}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${percentage.toInt()}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Время: ${_formatTime(timeSpent)}',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              correctCount >= _questions.length * 0.7
                  ? 'Отлично! Тема усвоена!'
                  : 'Попробуйте ещё раз!',
              style: TextStyle(
                fontSize: 16,
                color: correctCount >= _questions.length * 0.7
                    ? AppTheme.success
                    : AppTheme.warning,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      final email = user?.email ?? 'unknown';
                      final recipient = teacherEmail.isNotEmpty
                          ? teacherEmail
                          : '?';
                      final subject = Uri.encodeComponent(
                          'Результат финального теста: $topicName');
                      final body = Uri.encodeComponent(
                        'Результат финального теста\n'
                        'Тема: $topicName\n'
                        'Результат: $correctCount из ${_questions.length}\n'
                        'Процент: ${percentage.toInt()}%\n'
                        'Время: ${_formatTime(timeSpent)}\n'
                        'Email ученика: $email',
                      );
                      final uri = Uri.parse(
                          'mailto:$recipient?subject=$subject&body=$body');
                      try {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } catch (_) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Не удалось открыть почтовый клиент'),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.email_rounded),
                    label: const Text('Отправить учителю'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('На главную'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Финальный тест')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppTheme.warning,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('На главную'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_testCompleted) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];
    final hasAnswer = _userAnswers[_currentIndex] != null;
    final answeredAll = _userAnswers.every((a) => a != null);

    final isLowTime = _timeSeconds <= 30;
    final timerColor = isLowTime
        ? AppTheme.error
        : _timeSeconds <= 60
            ? AppTheme.warning
            : Colors.white;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Вопрос ${_currentIndex + 1}/${_questions.length}'),
        automaticallyImplyLeading: false,
        leading: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(40),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => _finishTest(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_rounded, size: 18, color: timerColor),
                const SizedBox(width: 6),
                Text(
                  _formatTime(_timeSeconds),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: timerColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _questions.length,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                minHeight: 6,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: QuestionWidget(
                question: question,
                revealed: false,
                userAnswer: _userAnswers[_currentIndex],
                onAnswer: _answerQuestion,
              ),
            ),
          ),
          if (question.explanation.isNotEmpty && hasAnswer)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primary.withAlpha(50)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      question.explanation,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: hasAnswer ? _nextQuestion : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasAnswer ? AppTheme.primary : Colors.grey.shade300,
                  foregroundColor: hasAnswer ? Colors.white : Colors.grey.shade500,
                  elevation: hasAnswer ? 4 : 0,
                  shadowColor: hasAnswer ? AppTheme.primary.withAlpha(80) : null,
                ),
                child: Text(
                  answeredAll ? 'Завершить тест' : 'Далее',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
