import 'package:flutter/material.dart';

/// Brand palette taken from the web app (frontend/src/index.css and App.css)
/// and the mobile design document (360-Mobile-App-Sample-Screens.docx).
class AppColors {
  AppColors._();

  // Brand
  static const Color navy = Color(0xFF052949); // sidebar colour
  static const Color navyDark = Color(0xFF041F38);
  static const Color navyLight = Color(0xFF0D3A63); // active menu background
  static const Color orange = Color(0xFFF46D34); // brand mark / active marker
  static const Color orangeSoft = Color(0xFFFFF1E7);
  static const Color chartBlue = Color(0xFF17678E);

  // Surfaces
  static const Color background = Color(0xFFF3F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE6EDF5);
  static const Color divider = Color(0xFFEEF2F6);

  // Text
  static const Color textPrimary = Color(0xFF0B2A50);
  static const Color textSecondary = Color(0xFF526C91);
  static const Color textMuted = Color(0xFF8CA1B4);
  static const Color onDark = Color(0xFFFFFFFF);
  static const Color onDarkMuted = Color(0xFFBFD0E2);

  // Status (web dashboard badges)
  static const Color success = Color(0xFF148550);
  static const Color successSoft = Color(0xFFE8F7EF);
  static const Color warning = Color(0xFFA3660C);
  static const Color warningSoft = Color(0xFFFFF5DF);
  static const Color danger = Color(0xFFBB3A42);
  static const Color dangerSoft = Color(0xFFFCEBED);
  static const Color info = Color(0xFF1874C9);
  static const Color infoSoft = Color(0xFFEAF3FD);
  static const Color pink = Color(0xFFBE3275);
  static const Color pinkSoft = Color(0xFFF9EDF3);
  static const Color neutral = Color(0xFF64748B);
  static const Color neutralSoft = Color(0xFFEFF3F7);

  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF052949), Color(0xFF0B3D66)],
  );
}
