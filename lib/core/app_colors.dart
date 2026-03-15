import 'package:flutter/material.dart';

/// ELSA-inspired design system - đồng bộ với Frontend
class AppColors {
  // Primary (elsa-indigo)
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primaryLight = Color(0xFF818CF8);

  // Elsa palette
  static const Color elsaIndigo50 = Color(0xFFEEF2FF);
  static const Color elsaIndigo100 = Color(0xFFE0E7FF);
  static const Color elsaIndigo200 = Color(0xFFC7D2FE);
  static const Color elsaIndigo300 = Color(0xFFA5B4FC);
  static const Color elsaIndigo400 = Color(0xFF818CF8);
  static const Color elsaIndigo500 = Color(0xFF6366F1);
  static const Color elsaIndigo600 = Color(0xFF4F46E5);
  static const Color elsaIndigo700 = Color(0xFF4338CA);
  static const Color elsaIndigo800 = Color(0xFF3730A3);
  static const Color elsaIndigo900 = Color(0xFF312E81);

  static const Color elsaPurple500 = Color(0xFFA855F7);
  static const Color elsaPurple600 = Color(0xFF9333EA);
  static const Color elsaPurple700 = Color(0xFF7C3AED);

  // Background (frontend: 240 20% 98% = #F8F7FF)
  static const Color background = Color(0xFFF8F7FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFEEF2FF);

  // Text (frontend: 243 47% 13% = #1E1B4B)
  static const Color textPrimary = Color(0xFF1E1B4B);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);

  // Accent
  static const Color accent = Color(0xFF6366F1);
  static const Color divider = Color(0xFFE5E7EB);

  // Auth (dark gradient + cyan CTA)
  static const Color authGradientStart = Color(0xFF1A1040);
  static const Color authGradientMid = Color(0xFF2D1F5E);
  static const Color authGradientEnd = Color(0xFF16103A);
  static const Color authCtaStart = Color(0xFF00BCD4);
  static const Color authCtaMid = Color(0xFF26C6DA);
  static const Color authCtaEnd = Color(0xFF4DD0E1);

  // Bottom Nav
  static const Color navActive = primary;
  static const Color navInactive = Color(0xFF9CA3AF);

  // Progress
  static const Color progressBg = Color(0xFFE0E7FF);
  static const Color progressFill = primary;
}
