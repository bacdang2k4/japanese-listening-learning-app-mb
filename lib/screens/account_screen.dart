import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_service.dart';
import '../core/app_bottom_nav.dart';
import '../core/app_colors.dart';
import '../core/auth_storage.dart';
import '../core/routes.dart';

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
      setState(() {
        _account = account;
        _profiles = profiles;
        _progress = progress;
        _levels = levels;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
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
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Tạo profile mới',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    const Text('Ảnh đại diện (tùy chọn)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                        if (picked != null) {
                          setModalState(() => avatarFile = File(picked.path));
                        }
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.cardBg,
                          image: avatarFile != null
                              ? DecorationImage(image: FileImage(avatarFile!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: avatarFile == null
                            ? const Icon(Icons.add_a_photo, color: AppColors.textSecondary)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Tên profile (tùy chọn)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'VD: Học N5',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Cấp độ bắt đầu', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedLevelId,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _levels.map((l) {
                        final id = l['id'] as int?;
                        final name = l['levelName']?.toString() ?? 'N/A';
                        return DropdownMenuItem(value: id, child: Text(name));
                      }).toList(),
                      onChanged: (v) => setModalState(() => selectedLevelId = v),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
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
                            child: creating
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Tạo'),
                          ),
                        ),
                      ],
                    ),
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
        title: const Text('Đổi tên profile'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nhập tên profile',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
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
        title: const Text('Cá nhân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textSecondary),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Lỗi: $_error'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildAccountCard(),
                      const SizedBox(height: 16),
                      _buildProfileSwitcher(),
                      const SizedBox(height: 16),
                      _buildProfileProgressCard(),
                      const SizedBox(height: 16),
                      _buildProfilesList(),
                      const SizedBox(height: 16),
                      _buildMenuCard(),
                      const SizedBox(height: 16),
                      _buildLogoutButton(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardBg,
                  border: Border.all(color: AppColors.primary, width: 3),
                  image: avatarUrl != null && avatarUrl.isNotEmpty
                      ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? const Icon(Icons.person, size: 44, color: AppColors.primary)
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
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.surface, width: 2),
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
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email.isEmpty ? '—' : email,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.cardBg,
            backgroundImage: (activeAvatarUrl != null && activeAvatarUrl.isNotEmpty)
                ? NetworkImage(activeAvatarUrl)
                : null,
            child: (activeAvatarUrl == null || activeAvatarUrl.isEmpty)
                ? const Icon(Icons.person, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Profile đang học', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(activeTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          TextButton(
            onPressed: _profiles.isEmpty
                ? null
                : () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => _buildProfilePickerSheet(),
                    );
                  },
            child: const Text('Đổi'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePickerSheet() {
    final activeId = _activeProfileId;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Chọn profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ..._profiles.map((p) {
            final id = p['profileId'] as int?;
            final name = (p['name'] ?? '').toString().trim();
            final currentLevelName = (p['currentLevelName'] ?? '').toString();
            final avatarUrl = p['avatarUrl']?.toString();
            final isActive = id != null && id == activeId;
            final displayTitle = name.isNotEmpty ? name : 'Profile #$id';
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.cardBg,
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
                child: (avatarUrl == null || avatarUrl.isEmpty) ? const Icon(Icons.person) : null,
              ),
              title: Text(displayTitle),
              subtitle: Text(currentLevelName.isEmpty ? '—' : currentLevelName),
              trailing: isActive ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: id == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      await _switchProfile(id);
                    },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProfileProgressCard() {
    final summary = _getProgressSummary();
    final total = summary.totalTopics;
    final passed = summary.passedTopics;
    final ratio = total <= 0 ? 0.0 : passed / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tiến độ học', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            summary.levelName ?? '—',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppColors.progressBg,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đã hoàn thành $passed/$total chủ đề',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilesList() {
    if (_profiles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
        ),
        child: const Text('Tài khoản chưa có profile nào.'),
      );
    }

    final activeId = _activeProfileId;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Các profile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              TextButton.icon(
                onPressed: _showCreateProfileSheet,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tạo mới'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._profiles.map((p) {
            final id = p['profileId'] as int?;
            final name = (p['name'] ?? '').toString().trim();
            final currentLevelName = (p['currentLevelName'] ?? '').toString();
            final avatarUrl = p['avatarUrl']?.toString();
            final isActive = id != null && id == activeId;
            final displayTitle = name.isNotEmpty ? name : 'Profile #$id';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: isActive ? Border.all(color: AppColors.primary, width: 1.5) : null,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.surface,
                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty) ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayTitle,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          currentLevelName.isEmpty ? '—' : currentLevelName,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (id != null)
                    PopupMenuButton<String>(
                      tooltip: 'Avatar profile',
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
                          child: Text('Đổi avatar (chọn ảnh)'),
                        ),
                        PopupMenuItem(
                          value: 'editName',
                          child: Text('Đổi tên'),
                        ),
                        PopupMenuItem(
                          value: 'clear',
                          child: Text('Xóa avatar'),
                        ),
                      ],
                      icon: const Icon(Icons.image, color: AppColors.textSecondary),
                    ),
                  const SizedBox(width: 6),
                  if (!isActive)
                    SizedBox(
                      width: 72,
                      height: 40,
                      child: OutlinedButton(
                        onPressed: id == null ? null : () => _switchProfile(id),
                        child: const Text('Chọn'),
                      ),
                    )
                  else
                    const Icon(Icons.check_circle, color: AppColors.primary),
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
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Tài khoản',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: AppColors.primary, size: 22),
            title: const Text('Cài đặt', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
            onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
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
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 18),
            SizedBox(width: 8),
            Text('Đăng xuất'),
          ],
        ),
      ),
    );
  }
}
