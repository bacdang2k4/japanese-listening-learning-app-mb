import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_decorations.dart';
import '../core/routes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _darkMode = false;
  bool _soundEffects = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Cài đặt'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppDecorations.learnerBgGradient,
        ),
        child: Column(
          children: [
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Account section
                  _buildSectionTitle('Tài khoản'),
                  _buildCard([
                    _buildTile(
                      Icons.person,
                      'Thông tin cá nhân',
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.editProfile);
                      },
                    ),
                    const Divider(height: 1, color: AppColors.divider, indent: 64),
                    _buildTile(Icons.lock, 'Đổi mật khẩu'),
                    const Divider(height: 1, color: AppColors.divider, indent: 64),
                    _buildTile(Icons.credit_card, 'Gói đăng ký', trailing: _buildBadge('PRO', AppColors.primary)),
                  ]),
                  const SizedBox(height: 24),
                  // App settings
                  _buildSectionTitle('Ứng dụng'),
                  _buildCard([
                    _buildSwitchTile(
                      Icons.notifications,
                      'Thông báo',
                      _notifications,
                      (v) => setState(() => _notifications = v),
                    ),
                    const Divider(height: 1, color: AppColors.divider, indent: 64),
                    _buildSwitchTile(
                      Icons.dark_mode,
                      'Chế độ tối',
                      _darkMode,
                      (v) => setState(() => _darkMode = v),
                    ),
                    const Divider(height: 1, color: AppColors.divider, indent: 64),
                    _buildSwitchTile(
                      Icons.volume_up,
                      'Hiệu ứng âm thanh',
                      _soundEffects,
                      (v) => setState(() => _soundEffects = v),
                    ),
                    const Divider(height: 1, color: AppColors.divider, indent: 64),
                    _buildTile(
                      Icons.language,
                      'Ngôn ngữ',
                      trailing: const Text(
                        'Tiếng Việt',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  // Info
                  _buildSectionTitle('Thông tin'),
                  _buildCard([
                    _buildTile(Icons.info, 'Về ứng dụng'),
                    const Divider(height: 1, color: AppColors.divider, indent: 64),
                    _buildTile(Icons.description, 'Điều khoản sử dụng'),
                    const Divider(height: 1, color: AppColors.divider, indent: 64),
                    _buildTile(Icons.shield, 'Chính sách bảo mật'),
                    const Divider(height: 1, color: AppColors.divider, indent: 64),
                    _buildTile(Icons.help, 'Trợ giúp & Hỗ trợ'),
                  ]),
                  const SizedBox(height: 32),
                  // Version
                  const Center(
                    child: Text(
                      'JPLearning v1.0.0',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textHint),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppDecorations.elsaSm,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile(
    IconData icon,
    String title, {
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing:
          trailing ??
          const Icon(Icons.chevron_right, color: AppColors.textHint, size: 24),
      onTap: onTap ?? () {},
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildSwitchTile(
    IconData icon,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: AppColors.primary,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: AppColors.divider,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
