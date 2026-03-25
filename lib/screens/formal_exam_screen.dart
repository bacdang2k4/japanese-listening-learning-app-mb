import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import '../core/api_service.dart';
import '../core/app_colors.dart';
import '../core/auth_storage.dart';
import '../core/routes.dart';

class FormalExamScreen extends StatefulWidget {
  final int topicId;
  const FormalExamScreen({super.key, required this.topicId});

  @override
  State<FormalExamScreen> createState() => _FormalExamScreenState();
}

class _FormalExamScreenState extends State<FormalExamScreen> {
  // Data
  List<Map<String, dynamic>> _questions = [];
  Map<int, int?> _answers = {}; // questionId -> selectedAnswerId
  int? _resultId;

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _audioUrl;
  bool _isPlaying = false;
  List<bool> _audioPlayed = []; // track per question index
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  // UI State
  int _currentQuestion = 0;
  int get _totalQuestions => _questions.length;
  bool _loading = true;
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadExamData();
    _setupAudioListener();
  }

  void _setupAudioListener() {
    _audioPlayer.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() => _audioDuration = duration);
      }
    });
    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() => _audioPosition = position);
      }
    });
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state.playing);
        if (state.processingState == ProcessingState.completed) {
          // Mark current question as played
          if (_currentQuestion < _audioPlayed.length) {
            setState(() {
              _audioPlayed[_currentQuestion] = true;
            });
          }
        }
      }
    });
  }

  Future<void> _loadExamData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final topicId = widget.topicId;
      final profileId = AuthStorage.profileId;

      if (profileId == null) {
        throw Exception('Không tìm thấy profile');
      }

      // Get tests by topic
      final tests = await ApiService.getTestsByTopic(topicId);
      if (tests.isEmpty) {
        throw Exception('Không có bài thi trong chủ đề này');
      }

      // For now, auto-select first test (like frontend if only 1 test)
      final selectedTest = tests.first;
      final testId = selectedTest['testId'] as int;

      // Start test
      final startResult = await ApiService.startTest(testId, profileId);
      final testInfo = startResult as Map<String, dynamic>;
      final resultId = testInfo['resultId'] as int;
      final audioUrl = testInfo['audioUrl'] as String?;

      // Get questions
      final questions = await ApiService.getTestQuestions(testId, resultId);

      if (mounted) {
        setState(() {
          _resultId = resultId;
          _questions = questions.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _audioUrl = audioUrl;
          _audioPlayed = List<bool>.filled(_questions.length, false);
          _currentQuestion = 0; // Reset to first question
          _answers.clear(); // Reset answers
          _loading = false;
        });
      }

      // Load audio if exists
      if (audioUrl != null && audioUrl.isNotEmpty) {
        await _loadAudio(audioUrl);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadAudio(String url) async {
    try {
      await _audioPlayer.setUrl(url);
    } catch (e) {
      debugPrint('Failed to load audio: $e');
    }
  }

  void _togglePlayPause() async {
    if (_audioUrl == null || _audioUrl!.isEmpty) return;

    // Check if already played for current question
    if (_currentQuestion < _audioPlayed.length && _audioPlayed[_currentQuestion]) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Âm thanh chỉ được phát 1 lần duy nhất')),
      );
      return;
    }

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

  Future<void> _submitExam() async {
    final profileId = AuthStorage.profileId;
    if (profileId == null || _resultId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể nộp bài: thiếu thông tin')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      // Prepare answers
      final answersList = _questions.map((q) {
        final qid = q['questionId'] as int;
        final selectedId = _answers[qid];
        return {
          'questionId': qid,
          'selectedAnswerId': selectedId,
        };
      }).toList();

      final result = await ApiService.submitTest(
        _resultId!,
        profileId,
        answersList,
      );

      final scorePercent = result['score'] as int? ?? 0;
      final isPassed = result['isPassed'] as bool? ?? false;
      final correctCount = _totalQuestions > 0
          ? ((scorePercent / 100.0) * _totalQuestions).round()
          : 0;
      final wrongCount = _totalQuestions - correctCount;

      if (!mounted) return;

      // Navigate to result screen
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.examResult,
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
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
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
          title: const Text('Bài thi'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadExamData,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: Text('Không có câu hỏi')),
      );
    }

    final question = _questions[_currentQuestion];
    final questionId = question['questionId'] as int;
    final content = (question['content'] ?? '').toString();
    final answers = (question['answers'] as List<dynamic>? ?? [])
        .map((a) => a as Map<String, dynamic>)
        .toList();
    final selectedAnswerId = _answers[questionId];

    // Audio played status for current question
    final hasAudioPlayed = _currentQuestion < _audioPlayed.length && _audioPlayed[_currentQuestion];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Thoát bài thi?'),
                content: const Text('Bạn sẽ mất toàn bộ tiến trình nếu thoát.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('Thoát'),
                  ),
                ],
              ),
            );
          },
        ),
        title: const Column(
          children: [
            Text(
              'BÀI THI CHÍNH THỨC',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: 1,
              ),
            ),
            Text(
              'JPLearning Examination',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Header: Question counter + Timer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14),
                    children: [
                      const TextSpan(
                        text: 'Câu hỏi  ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextSpan(
                        text: '${_currentQuestion + 1}/$_totalQuestions',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer, size: 16, color: AppColors.error),
                      const SizedBox(width: 4),
                      const Text(
                        '30:00', // TODO: Implement real timer
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
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
                value: (_currentQuestion + 1) / _totalQuestions,
                backgroundColor: AppColors.progressBg,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
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
                  // Audio player (only if audioUrl exists)
                  if (_audioUrl != null && _audioUrl!.isNotEmpty)
                    _buildAudioPlayer(hasPlayed: hasAudioPlayed),
                  const SizedBox(height: 20),
                  // Question number label
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'CÂU HỎI ${String.fromCharCode(48 + (_currentQuestion + 1) ~/ 10)}${(_currentQuestion + 1) % 10}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Question text
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Answers
                  ...List.generate(answers.length, (i) {
                    final a = answers[i];
                    final label = String.fromCharCode('A'.codeUnitAt(0) + i);
                    final answerId = a['answerId'] as int?;
                    final isCorrect = a['isCorrect'] == true;
                    final isSelected = selectedAnswerId == answerId;
                    return _buildAnswer(
                      label,
                      (a['content'] ?? '').toString(),
                      answerId,
                      isSelected,
                      isCorrect,
                      selectedAnswerId != null, // show explanation if answer selected
                      () {
                        if (selectedAnswerId == null) {
                          setState(() {
                            _answers[questionId] = answerId;
                          });
                        }
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
                    onPressed: _currentQuestion > 0 ? () => setState(() => _currentQuestion--) : null,
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
                            if (_currentQuestion < _totalQuestions - 1) {
                              setState(() => _currentQuestion++);
                            } else {
                              _submitExam();
                            }
                          },
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_currentQuestion < _totalQuestions - 1 ? 'Tiếp theo' : 'Nộp bài'),
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

  Widget _buildAudioPlayer({required bool hasPlayed}) {
    if (_audioUrl == null || _audioUrl!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.audio_file, color: AppColors.textSecondary, size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Bài này không có âm thanh',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFEEF2FF),
                    Color(0xFFE0E7FF),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.elsaIndigo100.withValues(alpha: 0.8),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Play/Pause button
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: hasPlayed ? null : _togglePlayPause,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasPlayed ? AppColors.textHint : AppColors.primary,
                        shape: const CircleBorder(),
                        elevation: 0,
                        padding: EdgeInsets.zero,
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nghe đoạn hội thoại',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasPlayed
                              ? 'Đã nghe xong'
                              : (isPlaying ? 'Đang phát...' : 'Nhấn để phát'),
                          style: TextStyle(
                            fontSize: 13,
                            color: hasPlayed
                                ? AppColors.success
                                : AppColors.textSecondary.withValues(alpha: 0.8),
                          ),
                        ),
                        if (!hasPlayed) ...[
                          const SizedBox(height: 12),
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 16,
                              ),
                              activeTrackColor: AppColors.primary,
                              inactiveTrackColor: AppColors.progressBg,
                              thumbColor: AppColors.primary,
                              overlayColor: AppColors.primary.withValues(alpha: 0.2),
                            ),
                            child: Slider(
                              value: position.inMilliseconds.toDouble(),
                              min: 0,
                              max: duration.inMilliseconds > 0
                                  ? duration.inMilliseconds.toDouble()
                                  : 1,
                              onChanged: hasPlayed
                                  ? null
                                  : (value) async {
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (hasPlayed)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 40,
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
    bool isSelected,
    bool isCorrect,
    bool showExplanation,
    VoidCallback onTap,
  ) {
    Color borderColor = AppColors.divider;
    Color bgColor = AppColors.surface;
    Color circleColor = AppColors.cardBg;
    Color textColor = AppColors.textSecondary;
    Widget? trailingIcon;

    if (showExplanation) {
      if (isCorrect) {
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
                    color: (isSelected || isCorrect) && showExplanation
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
