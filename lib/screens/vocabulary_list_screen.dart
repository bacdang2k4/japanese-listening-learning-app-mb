import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/app_colors.dart';
import '../core/app_decorations.dart';
import '../widgets/skeleton.dart';
import 'practice_quiz_screen.dart';
import 'flashcard_screen.dart';
import '../core/auth_storage.dart';

class VocabularyListScreen extends StatefulWidget {
  final int? topicId;
  final int? testId;
  final String? testName;

  const VocabularyListScreen({
    super.key,
    this.topicId,
    this.testId,
    this.testName,
  });

  @override
  State<VocabularyListScreen> createState() => _VocabularyListScreenState();
}

class _VocabularyListScreenState extends State<VocabularyListScreen> {
  int _selectedFilter = 0;
  final _filters = ['Tất cả', 'Chưa thuộc', 'Đã thuộc'];

  bool _loading = true;
  String? _error;
  List<_VocabItem> _vocabItems = [];
  bool _starting = false;

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
        _vocabItems = [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiService.getVocabulariesByTopic(topicId);
      if (mounted) {
        setState(() {
          _vocabItems = list
              .map(
                (v) => _VocabItem(
                  (v['word'] ?? '').toString(),
                  (v['romaji'] ?? v['kana'] ?? '').toString(),
                  (v['meaning'] ?? '').toString(),
                  false,
                ),
              )
              .toList();
          _loading = false;
        });
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
        title: Text(widget.testId != null ? 'Ôn tập từ vựng' : 'Danh sách từ vựng'),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          if (widget.testId != null && widget.testName != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.elsaIndigo50,
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trước khi làm bài:',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.testName!,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                  ),
                ],
              ),
            ),
          // Search bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm từ vựng, ý nghĩa...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint, size: 24),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ),
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedFilter == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.divider,
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [],
                      ),
                      child: Text(
                        _filters[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Vocab list
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _loading
                  ? _buildSkeletonList()
                  : _error != null
                      ? Center(child: Text('Lỗi: $_error'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: _vocabItems.length,
                          itemBuilder: (context, index) {
                            return _buildVocabCard(_vocabItems[index]);
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.testId != null
          ? AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _starting ? 64 : 200,
              height: 56,
              child: FloatingActionButton.extended(
                onPressed: _starting ? null : _startTest,
                label: _starting
                    ? const SizedBox.shrink()
                    : const Text(
                        'Bắt đầu bài thi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                icon: _starting 
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      ) 
                    : const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                backgroundColor: AppColors.primary,
                elevation: 4,
              ),
            )
          : FloatingActionButton(
              onPressed: () {},
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              const Skeleton(width: 48, height: 48, borderRadius: 16),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Skeleton(height: 24, width: 80),
                        SizedBox(width: 12),
                        Skeleton(height: 16, width: 100),
                      ],
                    ),
                    SizedBox(height: 12),
                    Skeleton(height: 16, width: 150),
                    SizedBox(height: 12),
                    Skeleton(height: 20, width: 80, borderRadius: 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startTest() async {
    final testId = widget.testId;
    final profileId = AuthStorage.profileId;
    if (testId == null || profileId == null) return;

    setState(() => _starting = true);
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
      if (mounted) setState(() => _starting = false);
    }
  }

  Widget _buildVocabCard(_VocabItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppDecorations.elsaSm,
        border: Border.all(color: AppColors.divider),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            final topicId = widget.topicId;
            if (topicId == null) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FlashcardScreen(topicId: topicId),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.volume_up,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.kanji,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.romaji,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.meaning,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: item.isLearned
                              ? AppColors.success.withValues(alpha: 0.15)
                              : AppColors.elsaIndigo50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.isLearned ? 'ĐÃ THUỘC' : 'CHƯA THUỘC',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: item.isLearned
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textHint, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VocabItem {
  final String kanji;
  final String romaji;
  final String meaning;
  final bool isLearned;

  _VocabItem(this.kanji, this.romaji, this.meaning, this.isLearned);
}
