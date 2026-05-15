import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../services/firestore_service.dart';
import '../../models/topic_model.dart';
import '../../core/theme/app_theme.dart';

class ModuleSelectionScreen extends ConsumerStatefulWidget {
  const ModuleSelectionScreen({super.key});

  @override
  ConsumerState<ModuleSelectionScreen> createState() =>
      _ModuleSelectionScreenState();
}

class _ModuleSelectionScreenState
    extends ConsumerState<ModuleSelectionScreen> {
  final List<String> _grades = ['7 класс', '8 класс', '9 класс'];

  String? _selectedGrade;
  TopicModel? _selectedTopic;
  List<TopicModel> _topics = [];
  bool _isLoadingTopics = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final savedGrade = ref.read(selectedGradeProvider);
    if (savedGrade != null) {
      setState(() {
        _selectedGrade = savedGrade;
      });
      await _loadTopicsForGrade(savedGrade);

      final savedTopicId = ref.read(selectedTopicIdProvider);
      if (savedTopicId != null && _topics.isNotEmpty) {
        final foundTopic = _topics.firstWhere(
          (t) => t.id == savedTopicId,
          orElse: () => _topics.firstWhere(
            (t) => t.title == ref.read(selectedTopicProvider),
            orElse: () => _topics.first,
          ),
        );
        setState(() {
          _selectedTopic = foundTopic;
        });
      }
    }
  }

  Future<void> _loadTopicsForGrade(String grade) async {
    if (!mounted) return;

    setState(() {
      _isLoadingTopics = true;
      _selectedTopic = null;
      _topics = [];
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('topics')
          .where('grade', isEqualTo: grade)
          .orderBy('order')
          .get();

      final topics = querySnapshot.docs
                    .map((doc) =>
                        TopicModel.fromJson(doc.id, doc.data()))
          .toList();

      if (mounted) {
        setState(() {
          _topics = topics;
          _isLoadingTopics = false;
        });
      }

      if (topics.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Для класса $grade пока нет доступных тем'),
            backgroundColor: AppTheme.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTopics = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _saveSelection() async {
    if (_selectedGrade == null || _selectedTopic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите класс и тему'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = true);

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        await FirestoreService().updateUser(userId, {
          'selectedGrade': _selectedGrade,
          'selectedTopic': _selectedTopic!.title,
          'selectedTopicId': _selectedTopic!.id,
        });
      } catch (e) {
        print('Ошибка сохранения: $e');
      }
    }

    ref.read(selectedGradeProvider.notifier).state = _selectedGrade;
    ref.read(selectedTopicProvider.notifier).state = _selectedTopic!.title;
    ref.read(selectedTopicIdProvider.notifier).state = _selectedTopic!.id;
    ref.read(refreshUserDataProvider.notifier).state =
        !ref.read(refreshUserDataProvider.notifier).state;

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выбор сохранён!'),
          backgroundColor: AppTheme.success,
        ),
      );
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Выбор учебного модуля')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.primaryBoxDecoration,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.computer_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Выбор модуля',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Выберите ваш класс и тему',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.school_outlined,
                          color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Класс',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedGrade,
                    decoration: const InputDecoration(
                      hintText: 'Выберите класс',
                    ),
                    items: _grades.map((grade) {
                      return DropdownMenuItem(
                        value: grade,
                        child: Text(grade),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGrade = value;
                        _selectedTopic = null;
                      });
                      if (value != null) {
                        _loadTopicsForGrade(value);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.topic_outlined,
                          color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Тема по информатике',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_selectedGrade == null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Center(
                        child: Text(
                          'Сначала выберите класс',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    )
                  else if (_isLoadingTopics)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primary,
                          ),
                        ),
                      ),
                    )
                  else if (_topics.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Center(
                        child: Text(
                          'Нет доступных тем для этого класса',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    )
                  else
                    DropdownButtonFormField<TopicModel>(
                      value: _selectedTopic,
                      decoration: const InputDecoration(
                        hintText: 'Выберите тему',
                      ),
                      items: _topics.map((topic) {
                        return DropdownMenuItem(
                          value: topic,
                          child: Text(topic.title),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedTopic = value),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed:
                    (_isSaving || _selectedGrade == null || _selectedTopic == null)
                        ? null
                        : _saveSelection,
                icon: const Icon(Icons.save_rounded),
                label: Text(
                  _isSaving ? 'Сохранение...' : 'Сохранить выбор',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppTheme.success.withAlpha(80),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
