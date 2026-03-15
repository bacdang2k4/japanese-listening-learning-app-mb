import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/app_colors.dart';
import '../core/app_decorations.dart';
import '../core/app_bottom_nav.dart';
import '../core/auth_storage.dart';
import '../core/routes.dart';
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
      if (mounted) setState(() {
        _topics = topics.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _topicsLoading = false;
      });
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Lỗi: $_error'))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Học từ vựng',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Chọn chủ đề để bắt đầu học từ vựng tiếng Nhật',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_levels.isNotEmpty)
                            SizedBox(
                              height: 44,
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
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(name),
                                      selected: isSelected,
                                      selectedColor: AppColors.primary,
                                      onSelected: (_) {
                                        if (id != null) {
                                          setState(() => _selectedLevelId = id);
                                          _loadTopics();
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _topicsLoading
                                ? const Center(child: CircularProgressIndicator())
                                : _topics.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'Chưa có chủ đề nào trong cấp độ này.',
                                          style: TextStyle(color: AppColors.textSecondary),
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
                                          return Card(
                                            margin: const EdgeInsets.only(bottom: 12),
                                            child: ListTile(
                                              leading: Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Icon(Icons.menu_book, color: AppColors.primary),
                                              ),
                                              title: Text(
                                                topicName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: isUnlocked ? AppColors.textPrimary : AppColors.textHint,
                                                ),
                                              ),
                                              subtitle: Text(
                                                'Đơn vị ${topic['topicOrder'] ?? index + 1}',
                                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                              ),
                                              trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
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
                                            ),
                                          );
                                        },
                                      ),
                          ),
                        ],
                      ),
          ),
          const AppBottomNav(currentIndex: 1),
        ],
        ),
      ),
    );
  }
}
