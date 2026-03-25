import 'dart:math';
import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/app_colors.dart';
import '../core/app_decorations.dart';
import '../core/auth_storage.dart';
import 'practice_quiz_screen.dart';

class PracticeResultScreen extends StatefulWidget {
  final int score;
  final int correctCount;
  final int wrongCount;
  final int totalQuestions;
  final bool isPassed;
  final int? testId;
  final String? testName;

  const PracticeResultScreen({
    super.key,
    required this.score,
    required this.correctCount,
    required this.wrongCount,
    required this.totalQuestions,
    required this.isPassed,
    this.testId,
    this.testName,
  });

  @override
  State<PracticeResultScreen> createState() => _PracticeResultScreenState();
}

class _PracticeResultScreenState extends State<PracticeResultScreen> with SingleTickerProviderStateMixin {
  bool _retrying = false;
  late AnimationController _animationController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    final ratio = widget.totalQuestions <= 0 ? 0.0 : (widget.correctCount / widget.totalQuestions).clamp(0.0, 1.0);
    _scoreAnimation = Tween<double>(begin: 0, end: ratio).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onRetry() async {
    final testId = widget.testId;
    final profileId = AuthStorage.profileId;
    if (testId == null || profileId == null) return;

    setState(() => _retrying = true);
    try {
      final start = await ApiService.startTest(testId, profileId);
      final resultId = start['resultId'] as int?;
      final totalQuestions = start['totalQuestions'] as int?;
      final testName = start['testName']?.toString() ?? widget.testName ?? 'Luyện tập';
      final audioUrl = start['audioUrl']?.toString();

      if (!mounted || resultId == null) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PracticeQuizScreen(
            testId: testId,
            resultId: resultId,
            testName: testName,
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
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Kết quả bài tập'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Score circle
            SizedBox(
              width: 200,
              height: 200,
              child: AnimatedBuilder(
                animation: _scoreAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ScoreCirclePainter(_scoreAnimation.value, AppColors.primary),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(_scoreAnimation.value * widget.totalQuestions).round()}/${widget.totalQuestions}',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Text(
                            'ĐIỂM SỐ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              ),
            ),
            const SizedBox(height: 32),
            // Pass badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: widget.isPassed ? AppColors.successLight : AppColors.errorLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.isPassed ? AppColors.success : AppColors.error,
                  width: 1.5,
                ),
                boxShadow: widget.isPassed 
                    ? [BoxShadow(color: AppColors.success.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isPassed ? Icons.emoji_events : Icons.cancel,
                    color: widget.isPassed ? AppColors.success : AppColors.error,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isPassed ? 'ĐẠT YÊU CẦU' : 'CHƯA ĐẠT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: widget.isPassed ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.isPassed
                  ? 'Tuyệt vời! Bạn đã nắm vững kiến\nthức phần này.'
                  : 'Bạn cần luyện thêm để mở khóa\nbài học tiếp theo.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tổng quan chi tiết',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Stats grid
            Row(
              children: [
                _buildStatCard(
                  'ĐỘ CHÍNH XÁC',
                  widget.totalQuestions > 0
                      ? '${((widget.correctCount / widget.totalQuestions) * 100).round()}%'
                      : '0%',
                  Icons.my_location,
                  AppColors.primary,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'CÂU ĐÚNG',
                  '${widget.correctCount}',
                  Icons.check_circle,
                  AppColors.success,
                  bgColor: AppColors.successLight,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  'CÂU SAI',
                  '${widget.wrongCount}',
                  Icons.cancel,
                  AppColors.error,
                  bgColor: AppColors.errorLight,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'TỔNG SỐ',
                  '${widget.totalQuestions}',
                  Icons.format_list_numbered,
                  AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Advice card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppDecorations.elsaSm,
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.info, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lời khuyên cho bạn',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.wrongCount > 0
                              ? 'Bạn làm sai ${widget.wrongCount} câu. Hãy xem lại từ vựng và làm lại để củng cố kiến thức nhé!'
                              : 'Hoàn hảo! Bạn đã trả lời đúng tất cả các câu hỏi.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Retry button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: widget.testId != null && !_retrying ? _onRetry : null,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                child: _retrying
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Làm lại bài',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: const BorderSide(color: AppColors.divider, width: 2),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Trở về lộ trình',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    Color? bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor ?? AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: bgColor == null ? AppDecorations.elsaSm : [],
          border: bgColor == null ? Border.all(color: AppColors.divider) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: color == AppColors.primary
                    ? AppColors.textPrimary
                    : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreCirclePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScoreCirclePainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background circle
    final bgPaint = Paint()
      ..color = AppColors.progressBg
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
