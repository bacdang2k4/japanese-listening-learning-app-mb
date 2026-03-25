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
    _pageController.dispose();
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
          'Đánh giá chính xác năng lực hiện tại với hệ thống kiểm tra thông minh dựa trên AI.',
      illustration: '🤖',
      isDark: true,
    ),
    _OnboardingPage(
      icon: Icons.bar_chart,
      iconBgColor: const Color(0xFFF0F4F8),
      title: 'Cá nhân hoá lộ trình',
      subtitle: 'Tạo hồ sơ để theo dõi tiến độ và mục tiêu học tập của riêng bạn',
      illustration: '🎯',
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
          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.elsaIndigo50,
                image: _avatarFile != null
                    ? DecorationImage(
                        image: FileImage(_avatarFile!),
                        fit: BoxFit.cover,
                      )
                    : null,
                border: Border.all(color: AppColors.divider),
              ),
              child: _avatarFile == null
                  ? const Icon(Icons.add_a_photo, color: AppColors.primary, size: 24)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ảnh đại diện',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _avatarFile != null ? 'Đã chọn ảnh thành công' : 'Chạm để tải ảnh lên (tùy chọn)',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (_avatarFile != null)
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _avatarFile = null),
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                ),
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
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    TextButton(
                      onPressed: _loading ? null : _createProfileAndGoRoadmap,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(60, 48), // Touch target
                      ),
                      child: Text(
                        _currentPage == 0 ? 'Bỏ qua' : 'Skip',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
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
                              gradient: page.isDark 
                                  ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                                    )
                                  : const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFFE0E7FF), Color(0xFFC7D2FE)],
                                    ),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: AppDecorations.elsaMd,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    page.illustration,
                                    style: const TextStyle(fontSize: 80),
                                  ),
                                  const SizedBox(height: 16),
                                  if (page.isDark)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.cyanAccent.withValues(alpha: 0.1),
                                        border: Border.all(
                                          color: Colors.cyanAccent.withValues(alpha: 0.3),
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Text(
                                        'AI',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.cyanAccent,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),
                          // Title
                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
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
                              fontSize: 16,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          if (page.showStats) ...[
                            const SizedBox(height: 32),
                            // Avatar (optional)
                            _buildAvatarSection(),
                            const SizedBox(height: 16),
                            // Profile name input
                            TextField(
                              controller: _profileNameController,
                              style: const TextStyle(fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'Tên hồ sơ (tùy chọn)',
                                prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.divider),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.divider),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                ),
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
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: _currentPage == index ? 32 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.error, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              // Bottom button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  height: 56,
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
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: isLastPage ? 4 : 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLastPage ? 'Bắt đầu học' : 'Tiếp tục',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isLastPage ? Icons.rocket_launch : Icons.arrow_forward,
                                size: 20,
                              ),
                            ],
                          ),
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
