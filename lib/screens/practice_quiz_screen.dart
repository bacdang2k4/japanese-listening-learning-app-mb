import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import '../core/api_service.dart';
import '../core/app_colors.dart';
import '../core/app_decorations.dart';
import '../core/auth_storage.dart';
import 'practice_result_screen.dart';

class PracticeQuizScreen extends StatefulWidget {
  final int testId;
  final int resultId;
  final String testName;
  final int? totalQuestions;
  final String? audioUrl;

  const PracticeQuizScreen({
    super.key,
    required this.testId,
    required this.resultId,
    required this.testName,
    this.totalQuestions,
    this.audioUrl,
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

  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Timer
  DateTime? _startTime;
  Duration _elapsed = Duration.zero;
  bool _timerRunning = false;
  Timer? _timer;

  int get _totalQuestions => widget.totalQuestions ?? _questions.length;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _startTimer();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
      try {
        await _audioPlayer.setUrl(widget.audioUrl!);
      } catch (e) {
        debugPrint('Audio load error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tải âm thanh')),
          );
        }
      }
    }
  }

  void _startTimer() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startTime != null && _timerRunning && mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(_startTime!);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
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

      // Start timer on first load
      if (_startTime == null) {
        setState(() {
          _startTime = DateTime.now();
          _timerRunning = true;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _togglePlayPause() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.testName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        _formatDuration(_elapsed),
                        style: const TextStyle(
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
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: (_currentIndex + 1) / _totalQuestions),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    backgroundColor: AppColors.progressBg,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    minHeight: 8,
                  );
                }
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: SingleChildScrollView(
                key: ValueKey<int>(_currentIndex),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Audio player card
                    _buildAudioPlayer(),
                    if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty)
                      const SizedBox(height: 24),
                    
                    // Question text
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppDecorations.elsaSm,
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'CÂU HỎI',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textHint,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            content,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'CHỌN ĐÁP ÁN ĐÚNG NHẤT',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          // Bottom buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (_currentIndex > 0) ...[
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentIndex--;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        minimumSize: const Size(64, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Icon(Icons.chevron_left, size: 24),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting
                          ? null
                          : () {
                              if (_currentIndex < _totalQuestions - 1) {
                                setState(() {
                                  _currentIndex++;
                                });
                              } else {
                                _submit();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: _currentIndex < _totalQuestions - 1
                            ? AppColors.primary
                            : AppColors.success,
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentIndex < _totalQuestions - 1
                                      ? 'Tiếp theo'
                                      : 'Nộp bài',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentIndex < _totalQuestions - 1 ? Icons.chevron_right : Icons.check_circle_outline, 
                                  size: 20
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer() {
    if (widget.audioUrl == null || widget.audioUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<Duration?>(
      stream: _audioPlayer.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: _audioPlayer.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final isPlaying = _audioPlayer.playing;

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.elsaIndigo100),
                boxShadow: AppDecorations.elsaSm,
              ),
              child: Row(
                children: [
                  // Play/Pause button
                  GestureDetector(
                    onTap: _togglePlayPause,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPlaying ? 'Đang phát âm thanh' : 'Nhấn để nghe',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Progress slider
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 6,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16,
                            ),
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
                            thumbColor: AppColors.primary,
                            overlayColor: AppColors.primary.withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            value: position.inMilliseconds.toDouble(),
                            min: 0,
                            max: duration.inMilliseconds > 0
                                ? duration.inMilliseconds.toDouble()
                                : 1,
                            onChanged: (value) async {
                              await _audioPlayer.seek(
                                Duration(milliseconds: value.toInt()),
                              );
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
        trailingIcon = const Icon(Icons.check_circle, color: AppColors.success, size: 24);
      } else if (isSelected) {
        borderColor = AppColors.error;
        bgColor = AppColors.errorLight;
        circleColor = AppColors.error;
        textColor = AppColors.textPrimary;
        trailingIcon = const Icon(Icons.cancel, color: AppColors.error, size: 24);
      }
    } else if (isSelected) {
      borderColor = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: 0.05);
      circleColor = AppColors.primary;
      textColor = AppColors.primaryDark;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // >44px touch target
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: isSelected || (showExplanation && isCorrectAnswer) ? 2 : 1),
          boxShadow: isSelected && !showExplanation
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
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
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16, 
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (trailingIcon != null) trailingIcon,
          ],
        ),
      ),
    );
  }
}
