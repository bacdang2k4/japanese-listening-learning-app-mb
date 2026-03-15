import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/app_colors.dart';
import '../core/app_bottom_nav.dart';
import '../core/auth_storage.dart';
import '../core/routes.dart';

class ExamHistoryScreen extends StatefulWidget {
  const ExamHistoryScreen({super.key});

  @override
  State<ExamHistoryScreen> createState() => _ExamHistoryScreenState();
}

class _ExamHistoryScreenState extends State<ExamHistoryScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _searchTerm = '';
  int _page = 0;
  int _totalPages = 0;

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
      final data = await ApiService.getTestHistory(profileId, page: _page, size: 20);
      final content = data['content'] as List<dynamic>? ?? [];
      final totalPages = data['totalPages'] as int? ?? 0;
      if (mounted) setState(() {
        _items = content.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _totalPages = totalPages;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final dt = DateTime.tryParse(dateStr);
      if (dt == null) return dateStr;
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _searchTerm.isEmpty
        ? _items
        : _items.where((e) =>
            (e['testName']?.toString() ?? '').toLowerCase().contains(_searchTerm.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Lịch sử làm bài'),
        elevation: 0,
      ),
      body: Column(
        children: [
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên bài thi...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
              ),
              onChanged: (v) => setState(() => _searchTerm = v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Lỗi: $_error'))
                    : filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'Chưa có kết quả nào.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              final testName = item['testName']?.toString() ?? 'Bài thi';
                              final score = item['score'] as int? ?? 0;
                              final isPassed = item['isPassed'] as bool? ?? false;
                              final createdAt = item['createdAt']?.toString();
                              return GestureDetector(
                                onTap: () {
                                  final resultId = item['resultId'] as int?;
                                  final profileId = AuthStorage.profileId;
                                  if (resultId != null && profileId != null) {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.examHistoryDetail,
                                      arguments: {'resultId': resultId, 'profileId': profileId},
                                    );
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: (isPassed ? AppColors.success : AppColors.error).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          isPassed ? Icons.check_circle : Icons.cancel,
                                          color: isPassed ? AppColors.success : AppColors.error,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              testName,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _formatDate(createdAt),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '$score%',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: isPassed ? AppColors.success : AppColors.error,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isPassed ? AppColors.successLight : AppColors.errorLight,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              isPassed ? 'Đạt' : 'Chưa đạt',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: isPassed ? AppColors.success : AppColors.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
          const AppBottomNav(currentIndex: 2),
        ],
      ),
    );
  }
}
