import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/app_colors.dart';
import '../core/app_decorations.dart';
import '../core/app_bottom_nav.dart';
import '../core/auth_storage.dart';
import '../core/routes.dart';
import 'vocabulary_list_screen.dart';
import 'practice_quiz_screen.dart';

/// Lesson item in roadmap (vocabulary = bài 1, practice = bài 2, 3, ...)
class _LessonItem {
  final String id;
  final String title;
  final String typeLabel;
  final bool isVocabulary;
  final int? testId;
  final bool isCompleted;
  final bool isNext;

  _LessonItem({
    required this.id,
    required this.title,
    required this.typeLabel,
    required this.isVocabulary,
    this.testId,
    required this.isCompleted,
    required this.isNext,
  });
}

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  Map<String, dynamic>? _progress;
  List<TopicModel> _topics = [];
  Map<int, List<Map<String, dynamic>>> _topicTests = {};
  bool _loading = true;
  String? _error;
  String? _currentLevelName;
  int? _startingTestId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profileId = AuthStorage.profileId;
    if (profileId == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.profileSelection);
      }
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final progress = await ApiService.getProfileProgress(profileId);
      final levelsList = progress['levels'] as List<dynamic>? ?? [];
      Map<String, dynamic>? currentLevel;
      for (final l in levelsList) {
        final m = l as Map<String, dynamic>;
        if (m['status'] == 'LEARNING' || m['status'] == 'PASS') {
          currentLevel = m;
          break;
        }
      }
      currentLevel ??= levelsList.isNotEmpty ? levelsList.first as Map<String, dynamic> : null;
      final levelId = currentLevel?['levelId'] as int?;
      if (levelId == null) {
        setState(() { _loading = false; _topics = []; _currentLevelName = null; });
        return;
      }
      _currentLevelName = currentLevel?['levelName']?.toString();
      final topicData = await ApiService.getTopicsByLevel(levelId, profileId: profileId);
      final topics = topicData.map((t) => TopicModel.fromJson(t)).toList();
      final topicTests = <int, List<Map<String, dynamic>>>{};
      for (final t in topics) {
        try {
          topicTests[t.id] = await ApiService.getTestsByTopic(t.id);
        } catch (_) {
          topicTests[t.id] = [];
        }
      }
      setState(() {
        _progress = progress;
        _topics = topics;
        _topicTests = topicTests;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Map<String, dynamic>? _getTopicProgress(int topicId) {
    final levels = _progress?['levels'] as List<dynamic>?;
    if (levels == null) return null;
    for (final l in levels) {
      final topics = (l as Map)['topics'] as List<dynamic>?;
      if (topics == null) continue;
      for (final t in topics) {
        final m = t as Map<String, dynamic>;
        if (m['topicId'] == topicId) return m;
      }
    }
    return null;
  }

  List<_LessonItem> _getLessonsForTopic(TopicModel topic) {
    final tp = _getTopicProgress(topic.id);
    final isUnlocked = topic.isUnlocked;
    final tests = _topicTests[topic.id] ?? [];
    final isTopicPassed = tp?['status'] == 'PASS';
    final passedTestCount = (tp?['passedTestCount'] as int?) ?? 0;
    final nextIndex = !isUnlocked ? -1 : (isTopicPassed ? -1 : passedTestCount);

    final lessons = <_LessonItem>[];
    for (var i = 0; i < tests.length; i++) {
      final test = tests[i];
      final lessonIdx = i;
      lessons.add(_LessonItem(
        id: 'test-${test['testId']}',
        title: 'Bài tập ${i + 1}: ${test['testName']}',
        typeLabel: 'Luyện tập',
        isVocabulary: false,
        testId: test['testId'] as int?,
        isCompleted: isTopicPassed || nextIndex > lessonIdx,
        isNext: nextIndex == lessonIdx,
      ));
    }
    return lessons;
  }

  ({int passed, int total}) _getTopicLessonCount(TopicModel topic) {
    final lessons = _getLessonsForTopic(topic);
    final tp = _getTopicProgress(topic.id);
    final total = lessons.length;
    final passed = tp?['status'] == 'PASS' ? total : (tp?['passedTestCount'] as int? ?? 0);
    return (passed: passed, total: total);
  }

  Future<void> _startLesson(TopicModel topic, _LessonItem lesson) async {
    if (lesson.isVocabulary) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VocabularyListScreen(topicId: topic.id),
        ),
      );
      return;
    }
    // Practice lesson: start test directly (vocab has its own tab)
    final testId = lesson.testId;
    final profileId = AuthStorage.profileId;
    if (testId == null || profileId == null) return;

    setState(() => _startingTestId = testId);
    try {
      final start = await ApiService.startTest(testId, profileId);
      final resultId = start['resultId'] as int?;
      final totalQuestions = start['totalQuestions'] as int?;
      final testName = start['testName']?.toString() ?? lesson.title;

      if (!mounted || resultId == null) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PracticeQuizScreen(
            testId: testId,
            resultId: resultId,
            testName: testName,
            totalQuestions: totalQuestions,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _startingTestId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = AuthStorage.firstName ?? AuthStorage.lastName ?? 'Bạn';
    final displayName = name.isEmpty ? 'Bạn' : name;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Lộ trình'),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppDecorations.learnerBgGradient,
        ),
        child: Column(
        children: [
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Lỗi: $_error'))
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Text(
                            'Lộ trình học tập của $displayName',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_currentLevelName != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '$_currentLevelName • ${_topics.length} Đơn vị',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          ...List.generate(_topics.length, (index) {
                            final topic = _topics[index];
                            final count = _getTopicLessonCount(topic);
                            final lessons = _getLessonsForTopic(topic);
                            return _buildTopicBlock(topic, count.passed, count.total, lessons);
                          }),
                        ],
                      ),
          ),
          const AppBottomNav(currentIndex: 0),
        ],
        ),
      ),
    );
  }

  Widget _buildTopicBlock(TopicModel topic, int passed, int total, List<_LessonItem> lessons) {
    final progress = total > 0 ? passed / total : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppDecorations.elsaSm,
        border: Border.all(
          color: AppColors.elsaIndigo100.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF6366F1),
                            Color(0xFF4F46E5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          topic.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: topic.isUnlocked
                                  ? AppColors.textPrimary
                                  : AppColors.textHint,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$passed / $total Bài học',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.progressBg,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0 ? AppColors.success : AppColors.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ...lessons.map((lesson) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    lesson.isVocabulary ? Icons.menu_book : Icons.edit_note,
                    size: 20,
                    color: lesson.isCompleted
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: lesson.isCompleted
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          lesson.typeLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (lesson.isNext && topic.isUnlocked)
                    TextButton(
                      onPressed: _startingTestId != null
                          ? null
                          : () => _startLesson(topic, lesson),
                      child: _startingTestId == lesson.testId
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Bắt đầu'),
                    )
                  else if (lesson.isCompleted && !lesson.isVocabulary)
                    TextButton(
                      onPressed: _startingTestId != null
                          ? null
                          : () => _startLesson(topic, lesson),
                      child: _startingTestId == lesson.testId
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Làm lại'),
                    )
                  else if (lesson.isCompleted && lesson.isVocabulary)
                    const Icon(Icons.check_circle, color: AppColors.success, size: 22),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
