import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_service.dart';
import '../core/app_bottom_nav.dart';
import '../core/app_colors.dart';
import '../core/app_decorations.dart';
import '../core/auth_storage.dart';
import '../core/routes.dart';
import '../widgets/skeleton.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _loading = true;
  bool _savingAvatar = false;
  String? _error;

  Map<String, dynamic>? _account;
  List<Map<String, dynamic>> _profiles = [];
  Map<String, dynamic>? _progress;
  List<Map<String, dynamic>> _levels = [];

  int? get _activeProfileId => AuthStorage.profileId;

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
      final account = await ApiService.getMyAccount();
      final profiles = await ApiService.getMyProfiles();
      final levels = await ApiService.getLevels();
      final activeProfileId = _activeProfileId;
      Map<String, dynamic>? progress;
      if (activeProfileId != null) {
        progress = await ApiService.getProfileProgress(activeProfileId);
      }
      if (mounted) {
        setState(() {
          _account = account;
          _profiles = profiles;
          _progress = progress;
          _levels = levels;
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

  Future<void> _showCreateProfileSheet() async {
    int? selectedLevelId = _levels.isNotEmpty ? (_levels.first['id'] as int?) : null;
    final nameController = TextEditingController();
    File? avatarFile;
    var creating = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Tạo hồ sơ mới',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const Text('Ảnh đại diện (tùy chọn)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                          if (picked != null) {
                            setModalState(() => avatarFile = File(picked.path));
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.elsaIndigo50,
                            image: avatarFile != null
                                ? DecorationImage(image: FileImage(avatarFile!), fit: BoxFit.cover)
                                : null,
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                          ),
                          child: avatarFile == null
                              ? const Icon(Icons.add_a_photo, color: AppColors.primary, size: 28)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Tên hồ sơ (tùy chọn)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'VD: Luyện thi N5',
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
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Cấp độ bắt đầu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedLevelId,
                      decoration: InputDecoration(
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
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      items: _levels.map((l) {
                        final id = l['id'] as int?;
                        final name = l['levelName']?.toString() ?? 'N/A';
                        return DropdownMenuItem(value: id, child: Text(name, style: const TextStyle(fontSize: 16)));
                      }).toList(),
                      onChanged: (v) => setModalState(() => selectedLevelId = v),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                side: const BorderSide(color: AppColors.divider, width: 2),
                              ),
                              child: const Text('Hủy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: creating || selectedLevelId == null
                                  ? null
                                  : () async {
                                      setModalState(() => creating = true);
                                      try {
                                        final profile = await ApiService.createProfile(
                                          selectedLevelId!,
                                          name: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
                                        );
                                        final profileId = profile['profileId'] as int?;
                                        if (profileId != null && avatarFile != null) {
                                          try {
                                            await ApiService.uploadProfileAvatar(profileId, avatarFile!);
                                          } catch (_) {}
                                        }
                                        if (!mounted) return;
                                        Navigator.pop(ctx);
                                        await _load();
                                        if (profileId != null) await _switchProfile(profileId);
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                                          );
                                        }
                                      } finally {
                                        if (mounted) setModalState(() => creating = false);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: creating
                                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                  : const Text('Tạo mới', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _switchProfile(int profileId) async {
    await AuthStorage.setProfileId(profileId);
    if (!mounted) return;
    await _load();
  }

  Future<void> _pickAndUploadLearnerAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _savingAvatar = true);
    try {
      await ApiService.uploadLearnerAvatar(File(picked.path));
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _savingAvatar = false);
    }
  }

  Future<void> _deleteLearnerAvatar() async {
    setState(() => _savingAvatar = true);
    try {
      await ApiService.deleteLearnerAvatar();
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _savingAvatar = false);
    }
  }

  Future<void> _editProfileName(int profileId, String? currentName) async {
    final controller = TextEditingController(text: currentName ?? '');
    final newName = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đổi tên profile', style: TextStyle(fontWeight: FontWeight.w700)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Nhập tên profile',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (newName == null) return;
    try {
      await ApiService.updateProfile(profileId, name: newName);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _pickAndUploadProfileAvatar(int profileId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    try {
      await ApiService.uploadProfileAvatar(profileId, File(picked.path));
      if (!mounted) return;
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật avatar profile')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _deleteProfileAvatar(int profileId) async {
    try {
      await ApiService.updateProfile(profileId, avatarUrl: '');
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  ({String? levelName, int passedTopics, int totalTopics}) _getProgressSummary() {
    final levels = _progress?['levels'] as List<dynamic>? ?? [];
    Map<String, dynamic>? currentLevel;
    for (final l in levels) {
      final m = l as Map<String, dynamic>;
      if (m['status'] == 'LEARNING' || m['status'] == 'PASS') {
        currentLevel = m;
        break;
      }
    }
    currentLevel ??= levels.isNotEmpty ? levels.first as Map<String, dynamic> : null;
    final topics = (currentLevel?['topics'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
    final passed = topics.where((t) => t['status'] == 'PASS').length;
    final total = topics.length;
    return (
      levelName: currentLevel?['levelName']?.toString(),
      passedTopics: passed,
      totalTopics: total,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Cá nhân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textPrimary),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
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
                    ? _buildSkeletonLoading()
                    : _error != null
                        ? Center(child: Text('Lỗi: $_error'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView(
                              padding: const EdgeInsets.all(24),
                              children: [
                                _buildAccountCard(),
                                const SizedBox(height: 24),
                                _buildProfileSwitcher(),
                                const SizedBox(height: 24),
                                _buildProfileProgressCard(),
                                const SizedBox(height: 24),
                                _buildProfilesList(),
                                const SizedBox(height: 24),
                                _buildMenuCard(),
                                const SizedBox(height: 32),
                                _buildLogoutButton(),
                                const SizedBox(height: 48),
                              ],
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Skeleton(height: 180, borderRadius: 24),
        const SizedBox(height: 24),
        const Skeleton(height: 80, borderRadius: 16),
        const SizedBox(height: 24),
        const Skeleton(height: 140, borderRadius: 20),
        const SizedBox(height: 24),
        const Skeleton(height: 200, borderRadius: 20),
      ],
    );
  }

  Widget _buildAccountCard() {
    final firstName = (_account?['firstName'] ?? '').toString();
    final lastName = (_account?['lastName'] ?? '').toString();
    final username = (_account?['username'] ?? '').toString();
    final email = (_account?['email'] ?? '').toString();
    final avatarUrl = _account?['avatarUrl']?.toString();

    final displayName = ('$firstName $lastName').trim();
    final name = displayName.isEmpty ? username : displayName;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppDecorations.elsaMd,
        border: Border.all(color: AppColors.elsaIndigo100.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardBg,
                  border: Border.all(color: AppColors.primary, width: 3),
                  image: avatarUrl != null && avatarUrl.isNotEmpty
                      ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? const Icon(Icons.person, size: 48, color: AppColors.primary)
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: PopupMenuButton<String>(
                  enabled: !_savingAvatar,
                  onSelected: (v) {
                    if (v == 'upload') _pickAndUploadLearnerAvatar();
                    if (v == 'delete') _deleteLearnerAvatar();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'upload', child: Text('Đổi ảnh đại diện')),
                    const PopupMenuItem(value: 'delete', child: Text('Xóa ảnh đại diện')),
                  ],
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 3),
                    ),
                    child: _savingAvatar
                        ? const Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email.isEmpty ? '—' : email,
            style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSwitcher() {
    final activeId = _activeProfileId;
    final active = _profiles.cast<Map<String, dynamic>>().where((p) => p['profileId'] == activeId).toList();
    final activeAvatarUrl = active.isNotEmpty ? active.first['avatarUrl']?.toString() : null;
    final activeTitle = active.isNotEmpty
        ? (active.first['name']?.toString().trim().isNotEmpty == true
            ? '${active.first['name']} • ${active.first['currentLevelName'] ?? ''}'
            : 'Profile #${active.first['profileId']} • ${active.first['currentLevelName'] ?? ''}')
        : (activeId != null ? 'Profile #$activeId' : 'Chưa chọn profile');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppDecorations.elsaSm,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.elsaIndigo50,
              image: (activeAvatarUrl != null && activeAvatarUrl.isNotEmpty)
                  ? DecorationImage(image: NetworkImage(activeAvatarUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: (activeAvatarUrl == null || activeAvatarUrl.isEmpty)
                ? const Icon(Icons.person, color: AppColors.primary, size: 24)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hồ sơ đang học', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(activeTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: TextButton(
              onPressed: _profiles.isEmpty
                  ? null
                  : () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _buildProfilePickerSheet(),
                      );
                    },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Đổi', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePickerSheet() {
    final activeId = _activeProfileId;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Chọn hồ sơ học tập', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shrinkWrap: true,
                itemCount: _profiles.length,
                itemBuilder: (context, index) {
                  final p = _profiles[index];
                  final id = p['profileId'] as int?;
                  final name = (p['name'] ?? '').toString().trim();
                  final currentLevelName = (p['currentLevelName'] ?? '').toString();
                  final avatarUrl = p['avatarUrl']?.toString();
                  final isActive = id != null && id == activeId;
                  final displayTitle = name.isNotEmpty ? name : 'Hồ sơ #$id';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isActive ? AppColors.primary : AppColors.divider, width: isActive ? 2 : 1),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.elsaIndigo50,
                          image: (avatarUrl != null && avatarUrl.isNotEmpty) ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover) : null,
                        ),
                        child: (avatarUrl == null || avatarUrl.isEmpty) ? const Icon(Icons.person, color: AppColors.primary) : null,
                      ),
                      title: Text(displayTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(currentLevelName.isEmpty ? '—' : currentLevelName),
                      trailing: isActive ? const Icon(Icons.check_circle, color: AppColors.primary, size: 28) : null,
                      onTap: id == null
                          ? null
                          : () async {
                              Navigator.pop(context);
                              await _switchProfile(id);
                            },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileProgressCard() {
    final summary = _getProgressSummary();
    final total = summary.totalTopics;
    final passed = summary.passedTopics;
    final ratio = total <= 0 ? 0.0 : passed / total;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppDecorations.elsaMd,
        border: Border.all(color: AppColors.elsaIndigo100.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.trending_up, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Tiến độ học tập', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            summary.levelName ?? '—',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: AppColors.progressBg,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    value >= 1.0 ? AppColors.success : AppColors.primary,
                  ),
                  minHeight: 10,
                );
              }
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Đã hoàn thành $passed/$total chủ đề',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilesList() {
    if (_profiles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppDecorations.elsaSm,
          border: Border.all(color: AppColors.divider),
        ),
        child: const Center(child: Text('Tài khoản chưa có hồ sơ nào.', style: TextStyle(fontSize: 15, color: AppColors.textSecondary))),
      );
    }

    final activeId = _activeProfileId;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppDecorations.elsaMd,
        border: Border.all(color: AppColors.elsaIndigo100.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Quản lý hồ sơ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              TextButton.icon(
                onPressed: _showCreateProfileSheet,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Tạo mới', style: TextStyle(fontWeight: FontWeight.w700)),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._profiles.map((p) {
            final id = p['profileId'] as int?;
            final name = (p['name'] ?? '').toString().trim();
            final currentLevelName = (p['currentLevelName'] ?? '').toString();
            final avatarUrl = p['avatarUrl']?.toString();
            final isActive = id != null && id == activeId;
            final displayTitle = name.isNotEmpty ? name : 'Hồ sơ #$id';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary.withValues(alpha: 0.05) : AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isActive ? AppColors.primary : AppColors.divider, width: isActive ? 2 : 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.divider),
                      image: (avatarUrl != null && avatarUrl.isNotEmpty) ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover) : null,
                    ),
                    child: (avatarUrl == null || avatarUrl.isEmpty) ? const Icon(Icons.person, color: AppColors.textSecondary, size: 28) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayTitle,
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.w700,
                            color: isActive ? AppColors.primaryDark : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentLevelName.isEmpty ? '—' : currentLevelName,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (id != null)
                    PopupMenuButton<String>(
                      tooltip: 'Tùy chọn',
                      onSelected: (v) {
                        if (v == 'upload') {
                          _pickAndUploadProfileAvatar(id);
                        } else if (v == 'clear') {
                          _deleteProfileAvatar(id);
                        } else if (v == 'editName') {
                          _editProfileName(id, p['name']?.toString());
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'upload',
                          child: Text('Đổi ảnh đại diện'),
                        ),
                        PopupMenuItem(
                          value: 'editName',
                          child: Text('Đổi tên hồ sơ'),
                        ),
                        PopupMenuItem(
                          value: 'clear',
                          child: Text('Xóa ảnh đại diện'),
                        ),
                      ],
                      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMenuCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppDecorations.elsaSm,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text(
              'Cài đặt khác',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.settings, color: AppColors.textSecondary, size: 22),
            ),
            title: const Text('Cài đặt chung', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textHint, size: 24),
            onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: () async {
          await AuthStorage.clear();
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.welcome,
            (route) => false,
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 22),
            SizedBox(width: 12),
            Text('Đăng xuất', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
