import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Đồng bộ với Frontend: elsa-sm, elsa-md, elsa-lg
class AppDecorations {
  static List<BoxShadow> get elsaSm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: const Color(0xFF4F46E5).withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elsaMd => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get elsaLg => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ];

  /// Gradient primary button (from-elsa-indigo-500 to-elsa-indigo-600)
  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
  );

  /// Auth CTA: cyan gradient
  static const LinearGradient authCtaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00BCD4),
      Color(0xFF26C6DA),
      Color(0xFF4DD0E1),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Auth background gradient
  static const LinearGradient authBgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A1040),
      Color(0xFF2D1F5E),
      Color(0xFF312050),
      Color(0xFF1E1545),
      Color(0xFF16103A),
    ],
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
  );

  /// Learner background gradient (F8F7FF via F3F1FF to EEF2FF)
  static const LinearGradient learnerBgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF8F7FF),
      Color(0xFFF3F1FF),
      Color(0xFFEEF2FF),
    ],
  );

  /// Card border (elsa-indigo-100/80)
  static Border get elsaCardBorder => Border.all(
        color: AppColors.elsaIndigo100.withValues(alpha: 0.8),
        width: 1,
      );
}
