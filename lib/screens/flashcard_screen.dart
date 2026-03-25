import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/app_colors.dart';
import '../core/app_decorations.dart';

class FlashcardScreen extends StatefulWidget {
  final int topicId;
  final String? topicName;

  const FlashcardScreen({
    super.key,
    required this.topicId,
    this.topicName,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  int _currentCard = 0;
  bool _showMeaning = false;
  bool _isFavorite = false;

  bool _loading = true;
  String? _error;
  List<_Flashcard> _cards = [];

  int get _totalCards => _cards.length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiService.getVocabulariesByTopic(widget.topicId);
      setState(() {
        _cards = list
            .map(
              (v) => _Flashcard(
                (v['word'] ?? '').toString(),
                (v['romaji'] ?? v['kana'] ?? '').toString(),
                (v['meaning'] ?? '').toString(),
                (v['exampleSentence'] ?? '').toString(),
              ),
            )
            .toList();
        _currentCard = 0;
        _showMeaning = false;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
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
          title: const Text('Flashcards'),
        ),
        body: Center(child: Text('Lỗi: $_error')),
      );
    }
    if (_cards.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Flashcards'),
        ),
        body: const Center(child: Text('Chủ đề này chưa có từ vựng')),
      );
    }

    final card = _cards[_currentCard.clamp(0, _cards.length - 1)];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'Chủ đề: ${widget.topicName ?? ''}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const Text(
              'JPLearning Flashcards',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppDecorations.learnerBgGradient,
        ),
        child: Column(
          children: [
            // Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tiến độ học tập',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text(
                      '${_currentCard + 1} / $_totalCards',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: (_currentCard + 1) / _totalCards),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      backgroundColor: AppColors.progressBg,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 8,
                    );
                  }
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Flashcard
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                        CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                      ),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Container(
                    key: ValueKey<int>(_currentCard),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: AppDecorations.elsaLg,
                      border: Border.all(
                        color: AppColors.elsaIndigo100.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Favorite star
                          Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              icon: Icon(
                                _isFavorite ? Icons.star : Icons.star_border,
                                color: _isFavorite ? Colors.amber : AppColors.textHint,
                                size: 32,
                              ),
                              onPressed: () {
                                setState(() => _isFavorite = !_isFavorite);
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Kanji
                          Text(
                            card.kanji,
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Romaji
                          Text(
                            card.romaji,
                            style: const TextStyle(
                              fontSize: 24,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Speaker
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.volume_up,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Show meaning button
                          GestureDetector(
                            onTap: () {
                              setState(() => _showMeaning = !_showMeaning);
                            },
                            behavior: HitTestBehavior.opaque,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: _showMeaning ? AppColors.surface : AppColors.primary.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: _showMeaning ? AppColors.divider : AppColors.primary.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _showMeaning ? Icons.translate : Icons.visibility,
                                    color: _showMeaning ? AppColors.textSecondary : AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _showMeaning ? card.meaning : 'Xem ý nghĩa',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _showMeaning ? AppColors.textPrimary : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Meaning + example
                          if (_showMeaning) ...[
                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    card.meaning,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (card.exampleSentence.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    const Text(
                                      'VÍ DỤ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      card.exampleSentence,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // "Đã thuộc từ này" button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showMeaning = false;
                      _currentCard = (_currentCard + 1) % _totalCards;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 24, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Đã thuộc từ này', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Prev / Next
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _currentCard > 0
                            ? () {
                                setState(() {
                                  _currentCard--;
                                  _showMeaning = false;
                                });
                              }
                            : null,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: const BorderSide(color: AppColors.divider, width: 2),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chevron_left, size: 24),
                            SizedBox(width: 8),
                            Text('Trước đó', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _currentCard = (_currentCard + 1) % _totalCards;
                            _showMeaning = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: const BorderSide(color: AppColors.primary, width: 2),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Tiếp theo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            SizedBox(width: 8),
                            Icon(Icons.chevron_right, size: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Flashcard {
  final String kanji;
  final String romaji;
  final String meaning;
  final String exampleSentence;

  _Flashcard(this.kanji, this.romaji, this.meaning, this.exampleSentence);
}
