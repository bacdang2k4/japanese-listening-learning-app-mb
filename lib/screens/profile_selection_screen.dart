import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/app_colors.dart';
import '../core/app_decorations.dart';
import '../core/auth_storage.dart';
import '../core/routes.dart';
import '../widgets/skeleton.dart';

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppDecorations.learnerBgGradient,
        ),
        child: Column(
          children: [
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Chào mừng bạn quay lại! Hãy chọn hồ sơ để tiếp tục hành trình học tập.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Profile grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _loading
                      ? _buildSkeletonGrid()
                      : GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 24,
                          childAspectRatio: 0.85,
                          children: [
                            ...profiles.map((p) => _buildProfileItem(context, p)),
                            _buildAddProfile(),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 24,
      crossAxisSpacing: 24,
      childAspectRatio: 0.85,
      children: List.generate(2, (index) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Skeleton(width: 100, height: 100, borderRadius: 50),
          SizedBox(height: 16),
          Skeleton(width: 80, height: 16),
          SizedBox(height: 8),
          Skeleton(width: 60, height: 12),
        ],
      )),
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
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppDecorations.elsaSm,
          border: Border.all(
            color: profile.isActive ? AppColors.primary : AppColors.divider,
            width: profile.isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.elsaIndigo50,
                    image: (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(profile.avatarUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 40, color: AppColors.primaryLight)
                      : null,
                ),
                if (profile.isActive)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: const Icon(Icons.check, size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              profile.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              profile.status,
              style: TextStyle(
                fontSize: 13,
                fontWeight: profile.isActive ? FontWeight.w600 : FontWeight.normal,
                color: profile.isActive
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddProfile() {
    return InkWell(
      onTap: () {
        Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primaryLight.withValues(alpha: 0.5),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.elsaIndigo50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Thêm mới',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
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
