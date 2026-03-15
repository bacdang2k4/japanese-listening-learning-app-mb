import 'package:flutter/material.dart';
import '../core/app_colors.dart';
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
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
            const Divider(height: 1, color: AppColors.divider, indent: 56),
            _buildTile(Icons.lock, 'Đổi mật khẩu'),
            const Divider(height: 1, color: AppColors.divider, indent: 56),
            _buildTile(Icons.credit_card, 'Gói đăng ký'),
          ]),
          const SizedBox(height: 20),
          // App settings
          _buildSectionTitle('Ứng dụng'),
          _buildCard([
            _buildSwitchTile(
              Icons.notifications,
              'Thông báo',
              _notifications,
              (v) => setState(() => _notifications = v),
            ),
            const Divider(height: 1, color: AppColors.divider, indent: 56),
            _buildSwitchTile(
              Icons.dark_mode,
              'Chế độ tối',
              _darkMode,
              (v) => setState(() => _darkMode = v),
            ),
            const Divider(height: 1, color: AppColors.divider, indent: 56),
            _buildSwitchTile(
              Icons.volume_up,
              'Hiệu ứng âm thanh',
              _soundEffects,
              (v) => setState(() => _soundEffects = v),
            ),
            const Divider(height: 1, color: AppColors.divider, indent: 56),
            _buildTile(
              Icons.language,
              'Ngôn ngữ',
              trailing: const Text(
                'Tiếng Việt',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          // Info
          _buildSectionTitle('Thông tin'),
          _buildCard([
            _buildTile(Icons.info, 'Về ứng dụng'),
            const Divider(height: 1, color: AppColors.divider, indent: 56),
            _buildTile(Icons.description, 'Điều khoản sử dụng'),
            const Divider(height: 1, color: AppColors.divider, indent: 56),
            _buildTile(Icons.shield, 'Chính sách bảo mật'),
            const Divider(height: 1, color: AppColors.divider, indent: 56),
            _buildTile(Icons.help, 'Trợ giúp & Hỗ trợ'),
          ]),
          const SizedBox(height: 20),
          // Version
          Center(
            child: Text(
              'Phiên bản 1.0.0',
              style: TextStyle(fontSize: 13, color: AppColors.textHint),
            ),
          ),
          const SizedBox(height: 20),
          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.welcome,
                  (route) => false,
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
        ],
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      trailing:
          trailing ??
          const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
