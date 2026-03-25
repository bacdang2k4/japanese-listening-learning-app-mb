import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/app_colors.dart';
import '../core/app_decorations.dart';
import '../core/app_bottom_nav.dart';
import '../core/auth_storage.dart';
import '../core/routes.dart';
import '../widgets/skeleton.dart';
import 'vocabulary_list_screen.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  List<Map<String, dynamic>> _levels = [];
  int? _selectedLevelId;
  List<Map<String, dynamic>> _topics = [];
  bool _loading = true;
  bool _topicsLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profileId = AuthStorage.profileId;
    if (profileId == null) {
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.profileSelection);
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final levels = await ApiService.getLevels();
      final levelId = levels.isNotEmpty ? (levels.first['id'] as int?) : null;
      setState(() {
        _levels = levels.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _selectedLevelId = levelId;
        _loading = false;
      });
      if (_selectedLevelId != null) _loadTopics();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _loadTopics() async {
    final levelId = _selectedLevelId;
    final profileId = AuthStorage.profileId;
    if (levelId == null || profileId == null) return;
    setState(() => _topicsLoading = true);
    try {
      final topics = await ApiService.getTopicsByLevel(levelId, profileId: profileId);
      if (mounted) {
        setState(() {
          _topics = topics.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _topicsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _topicsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Từ vựng'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppDecorations.learnerBgGradient,
        ),
        child: Column(
          children: [
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _loading
                    ? _buildScreenSkeleton()
                    : _error != null
                        ? Center(child: Text('Lỗi: $_error'))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Học từ vựng',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Chọn cấp độ và chủ đề để bắt đầu học',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_levels.isNotEmpty)
                                SizedBox(
                                  height: 48, // 48px height for good touch target
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: _levels.length,
                                    itemBuilder: (context, index) {
                                      final level = _levels[index];
                                      final id = level['id'] as int?;
                                      final name = level['levelName']?.toString() ?? 'N/A';
                                      final isSelected = id == _selectedLevelId;
                                      
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: GestureDetector(
                                          onTap: () {
                                            if (id != null && !isSelected) {
                                              setState(() => _selectedLevelId = id);
                                              _loadTopics();
                                            }
                                          },
                                          behavior: HitTestBehavior.opaque,
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
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
                                              name,
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: _topicsLoading
                                      ? _buildTopicsSkeleton()
                                      : _topics.isEmpty
                                          ? const Center(
                                              child: Text(
                                                'Chưa có chủ đề nào trong cấp độ này.',
                                                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                                              ),
                                            )
                                          : ListView.builder(
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              itemCount: _topics.length,
                                              itemBuilder: (context, index) {
                                                final topic = _topics[index];
                                                final topicId = topic['id'] as int?;
                                                final topicName = topic['topicName']?.toString() ?? 'Chủ đề';
                                                final isUnlocked = topic['isUnlocked'] ?? false;
                                                return Opacity(
                                                  opacity: isUnlocked ? 1.0 : 0.6,
                                                  child: Container(
                                                    margin: const EdgeInsets.only(bottom: 12),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.surface,
                                                      borderRadius: BorderRadius.circular(16),
                                                      boxShadow: AppDecorations.elsaSm,
                                                      border: Border.all(
                                                        color: isUnlocked 
                                                            ? AppColors.elsaIndigo100.withValues(alpha: 0.8)
                                                            : AppColors.divider,
                                                      ),
                                                    ),
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        borderRadius: BorderRadius.circular(16),
                                                        onTap: isUnlocked && topicId != null
                                                            ? () {
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder: (_) => VocabularyListScreen(topicId: topicId),
                                                                  ),
                                                                );
                                                              }
                                                            : null,
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(16),
                                                          child: Row(
                                                            children: [
                                                              Container(
                                                                width: 48,
                                                                height: 48,
                                                                decoration: BoxDecoration(
                                                                  color: isUnlocked
                                                                      ? AppColors.primary.withValues(alpha: 0.1)
                                                                      : Colors.grey.shade100,
                                                                  borderRadius: BorderRadius.circular(12),
                                                                ),
                                                                child: Icon(
                                                                  isUnlocked ? Icons.menu_book : Icons.lock, 
                                                                  color: isUnlocked ? AppColors.primary : Colors.grey.shade500,
                                                                ),
                                                              ),
                                                              const SizedBox(width: 16),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text(
                                                                      topicName,
                                                                      style: TextStyle(
                                                                        fontWeight: FontWeight.w700,
                                                                        fontSize: 16,
                                                                        color: isUnlocked ? AppColors.textPrimary : AppColors.textHint,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(height: 4),
                                                                    Text(
                                                                      'Đơn vị ${topic['topicOrder'] ?? index + 1}',
                                                                      style: const TextStyle(
                                                                        fontSize: 13, 
                                                                        color: AppColors.textSecondary,
                                                                        fontWeight: FontWeight.w500,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Icon(
                                                                Icons.chevron_right, 
                                                                color: isUnlocked ? AppColors.textPrimary : AppColors.textHint,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                ),
                              ),
                            ],
                          ),
              ),
            ),
            const AppBottomNav(currentIndex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Skeleton(height: 28, width: 150),
              SizedBox(height: 8),
              Skeleton(height: 16, width: 250),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: const [
              Skeleton(height: 48, width: 80, borderRadius: 24),
              SizedBox(width: 12),
              Skeleton(height: 48, width: 80, borderRadius: 24),
              SizedBox(width: 12),
              Skeleton(height: 48, width: 80, borderRadius: 24),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(child: _buildTopicsSkeleton()),
      ],
    );
  }

  Widget _buildTopicsSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              const Skeleton(width: 48, height: 48, borderRadius: 12),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Skeleton(height: 18, width: 120),
                    SizedBox(height: 8),
                    Skeleton(height: 14, width: 80),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
