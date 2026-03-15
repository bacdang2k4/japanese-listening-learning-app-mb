import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/app_colors.dart';
import '../core/auth_storage.dart';
import '../core/routes.dart';

class ProfileSelectionScreen extends StatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  List<Map<String, dynamic>> _profiles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.getMyProfiles();
      if (list.isEmpty && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
        return;
      }
      if (mounted) setState(() {
        _profiles = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileMaps = _loading ? AuthStorage.profiles : _profiles;
    final profiles = profileMaps.map((p) {
      final id = p['profileId'] as int?;
      final customName = (p['name'] ?? '').toString().trim();
      final name = customName.isNotEmpty
          ? customName
          : (p['currentLevelName']?.toString() ?? 'Hồ sơ ${id ?? ""}');
      final status = p['status']?.toString() ?? 'Đang học';
      final avatarUrl = p['avatarUrl']?.toString();
      return _Profile(name, status, false, id, avatarUrl);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        automaticallyImplyLeading: false,
        title: const Text('Chọn hồ sơ'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Chào mừng bạn quay lại! Hãy chọn hồ sơ để tiếp\ntục hành trình học tập.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          // Profile grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.85,
                children: [
                  ...profiles.map((p) => _buildProfileItem(context, p)),
                  _buildAddProfile(),
                ],
              ),
            ),
          ),
          // Add button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add, size: 20),
                  SizedBox(width: 8),
                  Text('Thêm hồ sơ mới'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context, _Profile profile) {
    return InkWell(
      onTap: () async {
        if (profile.profileId != null) {
          await AuthStorage.setProfileId(profile.profileId!);
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.roadmap,
              (route) => false,
            );
          }
        }
      },
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: profile.isActive
                        ? AppColors.primary
                        : AppColors.divider,
                    width: profile.isActive ? 3 : 2,
                  ),
                  color: AppColors.cardBg,
                  image: (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(profile.avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 48, color: AppColors.textHint)
                    : null,
              ),
              if (profile.isActive)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            profile.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            profile.status,
            style: TextStyle(
              fontSize: 12,
              color: profile.isActive
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddProfile() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.divider,
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: const Icon(Icons.add, size: 32, color: AppColors.textHint),
        ),
        const SizedBox(height: 8),
        const Text(
          'Thêm mới',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Profile {
  final String name;
  final String status;
  final bool isActive;
  final int? profileId;
  final String? avatarUrl;

  _Profile(this.name, this.status, this.isActive, this.profileId, [this.avatarUrl]);
}
