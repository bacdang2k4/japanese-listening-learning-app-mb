import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_service.dart';
import '../core/app_colors.dart';
import '../core/app_decorations.dart';
import '../core/auth_storage.dart';
import '../core/routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _loading = false;
  String? _error;
  File? _avatarFile;
  final TextEditingController _profileNameController = TextEditingController();

  @override
  void dispose() {
    _profileNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkExistingProfiles();
  }

  Future<void> _checkExistingProfiles() async {
    try {
      final profiles = await ApiService.getMyProfiles();
      if (profiles.isNotEmpty && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.profileSelection);
      }
    } catch (_) {
      // Ignore, show onboarding
    }
  }

  Future<void> _createProfileAndGoRoadmap() async {
    setState(() { _error = null; _loading = true; });
    try {
      final levels = await ApiService.getLevels();
      final levelId = levels.isNotEmpty ? (levels.first['id'] as int) : 1;
      final name = _profileNameController.text.trim();
      final profile = await ApiService.createProfile(levelId, name: name.isEmpty ? null : name);
      final profileId = profile['profileId'] as int?;
      if (profileId != null) {
        await AuthStorage.setProfileId(profileId);
        if (_avatarFile != null) {
          try {
            await ApiService.uploadProfileAvatar(profileId, _avatarFile!);
          } catch (_) {
            // Không chặn flow nếu upload avatar lỗi
          }
        }
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.roadmap,
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.style,
      iconBgColor: const Color(0xFFF0F0F0),
      title: 'Học từ vựng hiệu quả',
      subtitle:
          'Học từ vựng hiệu quả qua Flashcards sinh động và bài tập tương tác',
      illustration: '🃏',
    ),
    _OnboardingPage(
      icon: Icons.smart_toy,
      iconBgColor: const Color(0xFF1A2D3D),
      title: 'Kiểm tra AI',
      subtitle:
          'Kiểm tra năng lực với hệ thống AI thông minh, đánh giá chính xác trình độ hiện tại của bạn.',
      illustration: '🤖',
      isDark: true,
    ),
    _OnboardingPage(
      icon: Icons.bar_chart,
      iconBgColor: const Color(0xFFF0F4F8),
      title: 'Progress Tracking',
      subtitle: 'Theo dõi lộ trình và tiến độ học tập mỗi ngày',
      illustration: '📊',
      showStats: true,
    ),
  ];

  Widget _buildAvatarSection() {
    return GestureDetector(
      onTap: () async {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
        if (picked != null) {
          setState(() => _avatarFile = File(picked.path));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardBg,
                image: _avatarFile != null
                    ? DecorationImage(
                        image: FileImage(_avatarFile!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _avatarFile == null
                  ? const Icon(Icons.add_a_photo, color: AppColors.textSecondary, size: 24)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ảnh đại diện profile',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  Text(
                    _avatarFile != null ? 'Đã chọn ảnh' : 'Chạm để chọn (bỏ qua nếu không muốn)',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (_avatarFile != null)
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _avatarFile = null),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppDecorations.learnerBgGradient,
        ),
        child: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage == 0)
                    const SizedBox(width: 60)
                  else
                    const Text(
                      'JPLearning',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  TextButton(
                    onPressed: _loading ? null : _createProfileAndGoRoadmap,
                    child: Text(
                      _currentPage == 0 ? 'Bỏ qua' : 'Skip',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        const Spacer(),
                        // Illustration card
                        Container(
                          width: double.infinity,
                          height: 280,
                          decoration: BoxDecoration(
                            color: page.isDark
                                ? const Color(0xFF1A2D3D)
                                : AppColors.cardBg,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  page.illustration,
                                  style: const TextStyle(fontSize: 72),
                                ),
                                const SizedBox(height: 12),
                                if (page.isDark)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.cyanAccent.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'AI',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.cyanAccent,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Title
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Subtitle
                        Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        if (page.showStats) ...[
                          const SizedBox(height: 20),
                          // Avatar (optional)
                          _buildAvatarSection(),
                          const SizedBox(height: 16),
                          // Profile name input
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: TextField(
                              controller: _profileNameController,
                              decoration: InputDecoration(
                                hintText: 'Tên hồ sơ (tùy chọn)',
                                hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8)),
                                filled: true,
                                fillColor: AppColors.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Stats card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Thành tích tuần này',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Icon(
                                      Icons.trending_up,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text(
                                      '85%',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      '+12% vs tuần trước',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: 0.85,
                                    backgroundColor: AppColors.progressBg,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppColors.primary,
                                        ),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dots indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primary
                        : AppColors.progressBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            // Bottom button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ElevatedButton(
                onPressed: _loading
                    ? null
                    : () {
                        if (isLastPage) {
                          _createProfileAndGoRoadmap();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(isLastPage ? 'Bắt đầu ngay' : 'Tiếp theo'),
                          const SizedBox(width: 8),
                          Icon(
                            isLastPage ? Icons.rocket_launch : Icons.arrow_forward,
                            size: 20,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
        ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String illustration;
  final bool isDark;
  final bool showStats;

  _OnboardingPage({
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.illustration,
    this.isDark = false,
    this.showStats = false,
  });
}
