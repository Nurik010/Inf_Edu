import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:inf_edu_app/domain/entities/topic_model.dart';
import '../../app/providers.dart';
import '../../services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  TopicModel? _currentTopic;
  bool _isLoading = true;
  String? _error;
  String? _lastLoadedTopicId;
  bool _isTopicCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastLoadedTopicId = ref.read(selectedTopicIdProvider);
    _loadTopic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadTopic();
    }
  }

  Future<void> _loadTopic() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String? topicId = ref.read(selectedTopicIdProvider);

      if (topicId == null || topicId.isEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userData = await FirestoreService().getUser(user.uid);
          topicId = userData?.selectedTopicId;

          if (topicId != null) {
            ref.read(selectedTopicIdProvider.notifier).state = topicId;
            ref.read(selectedGradeProvider.notifier).state =
                userData?.selectedGrade;
            ref.read(selectedTopicProvider.notifier).state =
                userData?.selectedTopic;
          }
        }
      }

      if (topicId == null || topicId.isEmpty) {
        if (mounted) {
          setState(() {
            _currentTopic = null;
            _isLoading = false;
          });
        }
        return;
      }

      final topic = await FirestoreService().getTopic(topicId);

      final userId = FirebaseAuth.instance.currentUser?.uid;
      bool completed = false;
      if (userId != null && topicId.isNotEmpty) {
        final results = await FirestoreService().getTopicTestResults(userId, topicId);
        completed = results.any((r) => r.percentage >= 70);
      }

      if (mounted) {
        setState(() {
          _currentTopic = topic;
          _isTopicCompleted = completed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topicId = ref.watch(selectedTopicIdProvider);
    ref.watch(refreshUserDataProvider);

    if (topicId != _lastLoadedTopicId) {
      _lastLoadedTopicId = topicId;
      Future.microtask(() {
        if (mounted) _loadTopic();
      });
    }

    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('InfoEd', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25), ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.person_rounded),
              onPressed: () async {
                await context.push('/profile');
              },
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
              child: DrawerHeader(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'InfoEd',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Образовательная платформа',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _DrawerTile(
              icon: Icons.swap_horiz_rounded,
              title: 'Сменить тему',
              onTap: () async {
                Navigator.pop(context);
                await context.push('/module-selection');
                _loadTopic();
              },
            ),
            _DrawerTile(
              icon: Icons.check_circle_rounded,
              title: 'Пройденные темы',
              onTap: () {
                Navigator.pop(context);
                context.push('/completed-topics');
              },
            ),
            _DrawerTile(
              icon: Icons.bar_chart_rounded,
              title: 'Статистика',
              onTap: () {
                Navigator.pop(context);
                context.push('/stats');
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(),
            ),
            _DrawerTile(
              icon: Icons.person_rounded,
              title: 'Профиль',
              onTap: () async {
                Navigator.pop(context);
                await context.push('/profile');
                _loadTopic();
              },
            ),
          ],
        ),
      ),
      body: userAsync.when(
        data: (user) {
          if (_isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            );
          }

          if (_error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppTheme.error,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Произошла ошибка',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _loadTopic,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (_currentTopic == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        size: 48,
                        color: AppTheme.warning,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Тема не выбрана',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Выберите класс и тему для обучения',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await context.push('/module-selection');
                        _loadTopic();
                      },
                      icon: const Icon(Icons.school_rounded),
                      label: const Text('Выбрать тему'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadTopic,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await context.push('/module-selection');
                      _loadTopic();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.primaryBoxDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(40),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.menu_book_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentTopic!.title,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(40),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _currentTopic?.grade ?? 'Не выбран',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Теоретический материал',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.cardDecoration,
                    child: Markdown(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      data: _currentTopic!.content,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontSize: 17,
                          height: 1.6,
                          color: AppTheme.textPrimary,
                        ),
                        h1: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        h2: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        h3: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        listBullet: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
                        code: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                          backgroundColor: Color(0xFFF0F0F0),
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final currentTopicId =
                            ref.read(selectedTopicIdProvider);
                        if (currentTopicId == null ||
                            currentTopicId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Сначала выберите тему'),
                            ),
                          );
                          return;
                        }
                        await context.push('/test');
                        ref.read(refreshUserDataProvider.notifier).state =
                            !ref.read(refreshUserDataProvider.notifier).state;
                      },
                      icon: const Icon(Icons.quiz_rounded),
                      label: const Text(
                        'Пройти тест',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: AppTheme.success.withAlpha(80),
                      ),
                    ),
                  ),
                  if (_isTopicCompleted) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final currentTopicId =
                              ref.read(selectedTopicIdProvider);
                          if (currentTopicId == null ||
                              currentTopicId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Сначала выберите тему'),
                              ),
                            );
                            return;
                          }
                          await context.push('/final-test');
                          ref.read(refreshUserDataProvider.notifier).state =
                              !ref.read(refreshUserDataProvider.notifier).state;
                        },
                        icon: const Icon(Icons.workspace_premium_rounded),
                        label: const Text(
                          'Финальный тест',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: AppTheme.primary.withAlpha(80),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
        error: (_, __) => const Center(
          child: Text('Ошибка загрузки данных'),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppTheme.textSecondary,
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
