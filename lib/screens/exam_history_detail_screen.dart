import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/app_colors.dart';

class ExamHistoryDetailScreen extends StatefulWidget {
  final int resultId;
  final int profileId;

  const ExamHistoryDetailScreen({
    super.key,
    required this.resultId,
    required this.profileId,
  });

  @override
  State<ExamHistoryDetailScreen> createState() => _ExamHistoryDetailScreenState();
}

class _ExamHistoryDetailScreenState extends State<ExamHistoryDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getTestResultDetail(widget.resultId, widget.profileId);
      if (mounted) setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Chi tiết bài thi'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Chi tiết bài thi'),
        ),
        body: Center(child: Text('Lỗi: $_error')),
      );
    }

    final testName = _data!['testName']?.toString() ?? 'Bài thi';
    final score = _data!['score'] as int? ?? 0;
    final isPassed = _data!['isPassed'] as bool? ?? false;
    final totalTime = _data!['totalTime'] as int? ?? 0;
    final questionResults = _data!['questionResults'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Chi tiết bài thi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isPassed ? AppColors.success : AppColors.error).withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isPassed ? AppColors.successLight : AppColors.errorLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isPassed ? 'ĐẠT' : 'CHƯA ĐẠT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isPassed ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$score%',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '/${questionResults.length} câu',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  testName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoTag(
                      Icons.timer,
                      'THỜI GIAN',
                      totalTime > 0 ? '${totalTime ~/ 60} phút ${totalTime % 60}s' : '—',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Danh sách câu hỏi',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${questionResults.length} câu hỏi',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(questionResults.length, (index) {
            final q = questionResults[index] as Map<String, dynamic>;
            final content = q['questionContent']?.toString() ?? '';
            final selected = q['selectedAnswer']?.toString() ?? '(bỏ trống)';
            final correct = q['correctAnswer']?.toString() ?? '';
            final isCorrect = q['isCorrect'] as bool? ?? false;
            return _buildQuestionCard(index + 1, content, selected, correct, isCorrect);
          }),
        ],
      ),
    );
  }

  static Widget _buildInfoTag(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.textHint,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestionCard(int number, String question, String chosen, String correct, bool isCorrect) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CÂU $number',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? AppColors.success : AppColors.error,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isCorrect ? AppColors.successLight : AppColors.errorLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: isCorrect ? AppColors.success : AppColors.error,
                ),
                children: [
                  const TextSpan(
                    text: 'ĐÃ CHỌN:  ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: chosen),
                ],
              ),
            ),
          ),
          if (!isCorrect && correct.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  children: [
                    const TextSpan(
                      text: 'ĐÁP ÁN:  ',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: correct),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
