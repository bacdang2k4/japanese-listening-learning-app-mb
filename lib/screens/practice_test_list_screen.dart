import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/app_colors.dart';
import '../core/auth_storage.dart';
import 'practice_quiz_screen.dart';

class PracticeTestListScreen extends StatefulWidget {
  final int? topicId;

  const PracticeTestListScreen({super.key, this.topicId});

  @override
  State<PracticeTestListScreen> createState() => _PracticeTestListScreenState();
}

class _PracticeTestListScreenState extends State<PracticeTestListScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _tests = [];
  int? _startingTestId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final topicId = widget.topicId;
    if (topicId == null) {
      setState(() {
        _loading = false;
        _tests = [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tests = await ApiService.getTestsByTopic(topicId);
      setState(() {
        _tests = tests;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _startTest(Map<String, dynamic> test) async {
    final testId = test['testId'] as int?;
    final testName = test['testName']?.toString() ?? 'Luyện tập';
    final profileId = AuthStorage.profileId;
    if (testId == null || profileId == null) return;

    setState(() => _startingTestId = testId);
    try {
      final start = await ApiService.startTest(testId, profileId);
      final resultId = start['resultId'] as int?;
      final totalQuestions = start['totalQuestions'] as int?;
      final resolvedTestName = start['testName']?.toString() ?? testName ?? 'Luyện tập';
      final audioUrl = start['audioUrl']?.toString();

      if (!mounted || resultId == null) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PracticeQuizScreen(
            testId: testId,
            resultId: resultId,
            testName: resolvedTestName,
            totalQuestions: totalQuestions,
            audioUrl: audioUrl,
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Luyện tập'),
      ),
      body: Column(
        children: [
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Trình độ N5',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'JLPT N5',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stats row
                Row(
                  children: [
                    _buildStatCard('HOÀN\nTHÀNH', '12/20'),
                    const SizedBox(width: 10),
                    _buildStatCard('TRUNG\nBÌNH', '85%'),
                    const SizedBox(width: 10),
                    _buildStatCard('THỜI GIAN', '4.5h'),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Danh sách bài thi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                // Test list
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Center(child: Text('Lỗi: $_error'))
                else if (_tests.isEmpty)
                  const Center(child: Text('Chưa có bài luyện tập'))
                else
                  ...List.generate(_tests.length, (i) {
                    final t = _tests[i];
                    final duration = t['duration'] == null
                        ? '-'
                        : '${t['duration']} phút';
                    final passCondition = t['passCondition'] == null
                        ? '-'
                        : '${t['passCondition']}%';
                    return _buildTestCard(
                      context,
                      _TestItem(
                        '${i + 1}'.padLeft(2, '0'),
                        (t['testName'] ?? '').toString(),
                        duration,
                        passCondition,
                        t,
                        true,
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard(BuildContext context, _TestItem test) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: test.isAvailable
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'BÀI ${test.number}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (!test.isAvailable)
                const Icon(Icons.lock, color: AppColors.textHint, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            test.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: test.isAvailable
                  ? AppColors.textPrimary
                  : AppColors.textHint,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTestInfo(Icons.access_time, test.duration),
              const SizedBox(width: 12),
              _buildTestInfo(Icons.grade, 'Đạt: ${test.passRate}'),
            ],
          ),
          if (test.isAvailable) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startingTestId != null
                    ? null
                    : () {
                        final raw = test.raw;
                        if (raw == null) return;
                        _startTest(raw);
                      },
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 42)),
                child: _startingTestId == test.raw?['testId']
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Bắt đầu',
                        style: TextStyle(fontSize: 14),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTestInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _TestItem {
  final String number;
  final String title;
  final String duration;
  final String passRate;
  final bool isAvailable;
  final Map<String, dynamic>? raw;

  _TestItem(
    this.number,
    this.title,
    this.duration,
    this.passRate,
    this.raw,
    this.isAvailable,
  );
}
