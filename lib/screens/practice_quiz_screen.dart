import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/app_colors.dart';
import '../core/auth_storage.dart';
import 'practice_result_screen.dart';

class PracticeQuizScreen extends StatefulWidget {
  final int testId;
  final int resultId;
  final String testName;
  final int? totalQuestions;

  const PracticeQuizScreen({
    super.key,
    required this.testId,
    required this.resultId,
    required this.testName,
    this.totalQuestions,
  });

  @override
  State<PracticeQuizScreen> createState() => _PracticeQuizScreenState();
}

class _PracticeQuizScreenState extends State<PracticeQuizScreen> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  int _currentIndex = 0;

  List<Map<String, dynamic>> _questions = [];
  final Map<int, int?> _selectedAnswerByQuestionId = {};
  final Map<int, bool> _showExplanationByQuestionId = {};

  int get _totalQuestions => widget.totalQuestions ?? _questions.length;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiService.getTestQuestions(
        widget.testId,
        widget.resultId,
      );
      setState(() {
        _questions = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    final profileId = AuthStorage.profileId;
    if (profileId == null) return;
    setState(() => _submitting = true);
    try {
      final answers = _questions.map((q) {
        final qid = q['questionId'] as int;
        return {
          'questionId': qid,
          'selectedAnswerId': _selectedAnswerByQuestionId[qid],
        };
      }).toList();

      final result = await ApiService.submitTest(
        widget.resultId,
        profileId,
        answers,
      );
      final scorePercent = result['score'] as int? ?? 0;
      final isPassed = result['isPassed'] as bool? ?? false;
      final correctCount = _totalQuestions > 0
          ? ((scorePercent / 100.0) * _totalQuestions).round()
          : 0;
      final wrongCount = _totalQuestions - correctCount;
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PracticeResultScreen(
            score: scorePercent,
            correctCount: correctCount,
            wrongCount: wrongCount,
            totalQuestions: _totalQuestions,
            isPassed: isPassed,
            testId: widget.testId,
            testName: widget.testName,
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
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
          title: const Text('Luyện tập'),
        ),
        body: Center(child: Text('Lỗi: $_error')),
      );
    }
    if (_questions.isEmpty) {
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
        body: const Center(child: Text('Chưa có câu hỏi')),
      );
    }

    final q = _questions[_currentIndex];
    final questionId = q['questionId'] as int;
    final content = (q['content'] ?? '').toString();
    final answers = (q['answers'] as List<dynamic>? ?? [])
        .map((a) => a as Map<String, dynamic>)
        .toList();
    final selectedAnswerId = _selectedAnswerByQuestionId[questionId];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Luyện tập: ${widget.testName}'),
      ),
      body: Column(
        children: [
          // Question progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Câu hỏi ${_currentIndex + 1}/$_totalQuestions',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      const Text(
                        '14:25',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _totalQuestions,
                backgroundColor: AppColors.progressBg,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
                minHeight: 6,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Audio player card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.headphones,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Nghe đoạn hội thoại',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Text(
                                'Bấm nút để nghe nội dung...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Fake slider
                              Row(
                                children: [
                                  const Text(
                                    '0:12',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: 0.27,
                                      onChanged: (_) {},
                                      activeColor: AppColors.primary,
                                    ),
                                  ),
                                  const Text(
                                    '0:45',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppColors.textPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Question label
                  const Text(
                    'CÂU HỎI:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Question text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          content,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Chọn đáp án đúng nhất:',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Answers
                  ...List.generate(answers.length, (i) {
                    final a = answers[i];
                    final label = String.fromCharCode('A'.codeUnitAt(0) + i);
                    final answerId = a['answerId'] as int?;
                    final isCorrect = a['isCorrect'] == true;
                    final showExplanation = _showExplanationByQuestionId[questionId] ?? false;
                    return _buildAnswer(
                      label,
                      (a['content'] ?? '').toString(),
                      answerId,
                      isCorrect,
                      selectedAnswerId,
                      showExplanation,
                      () {
                        if (_showExplanationByQuestionId[questionId] == true) return;
                        setState(() {
                          _selectedAnswerByQuestionId[questionId] = answerId;
                          _showExplanationByQuestionId[questionId] = true;
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          // Bottom buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppColors.background,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _currentIndex > 0
                        ? () {
                            setState(() => _currentIndex--);
                          }
                        : null,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chevron_left, size: 20),
                        SizedBox(width: 4),
                        Text('Trước đó'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting
                        ? null
                        : () {
                            if (_currentIndex < _totalQuestions - 1) {
                              setState(() => _currentIndex++);
                            } else {
                              _submit();
                            }
                          },
                    child: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentIndex < _totalQuestions - 1
                                    ? 'Tiếp theo'
                                    : 'Nộp bài',
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right, size: 20),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswer(
    String label,
    String text,
    int? answerId,
    bool isCorrectAnswer,
    int? selectedAnswerId,
    bool showExplanation,
    VoidCallback onTap,
  ) {
    final isSelected = answerId != null && selectedAnswerId == answerId;
    Color borderColor = AppColors.divider;
    Color bgColor = AppColors.surface;
    Color circleColor = AppColors.cardBg;
    Color textColor = AppColors.textSecondary;
    Widget? trailingIcon;

    if (showExplanation) {
      if (isCorrectAnswer) {
        borderColor = AppColors.success;
        bgColor = AppColors.successLight;
        circleColor = AppColors.success;
        textColor = AppColors.textPrimary;
        trailingIcon = const Icon(Icons.check_circle, color: AppColors.success, size: 22);
      } else if (isSelected) {
        borderColor = AppColors.error;
        bgColor = AppColors.errorLight;
        circleColor = AppColors.error;
        textColor = AppColors.textPrimary;
        trailingIcon = const Icon(Icons.cancel, color: AppColors.error, size: 22);
      }
    } else if (isSelected) {
      borderColor = AppColors.primary;
      circleColor = AppColors.primary;
      textColor = AppColors.textPrimary;
      trailingIcon = const Icon(Icons.check_circle, color: AppColors.primary, size: 22);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: (isSelected || isCorrectAnswer) && showExplanation
                        ? Colors.white
                        : isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 18, color: textColor),
              ),
            ),
            if (trailingIcon != null) trailingIcon,
          ],
        ),
      ),
    );
  }
}
