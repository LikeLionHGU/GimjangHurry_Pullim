import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary (라임 그린)
  static const Color primary = Color(0xFFB1ED01);
  static const Color primary40 = Color(0x66B1ED01); // 40% opacity
  static const Color primary15 = Color(0x26B1ED01); // 15% opacity

  // Error / 측정 불가
  static const Color error = Color(0xFFF6531F);
  static const Color error15 = Color(0x26F6531F); // 15% opacity

  // Background
  static const Color background = Color(0xFF010101);

  // Surface / Secondary
  static const Color secondary = Color(0xFF1E1E1F);
  static const Color surface = Color(0xFF1E1E1F);
  static const Color cardBackground = Color(0xFF171819);

  // Functional greys
  static const Color toolSelectBox = Color(0xFF555555);
  static const Color textBox = Color(0xB3171819); // #171819 70% opacity
  static const Color textGrey = Color(0xFF999999);

  // Neutral
  static const Color grey = Color(0xFFD9D9D9);
  static const Color grey40 = Color(0x66D9D9D9); // 40% opacity

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF999999);
  static const Color textTertiary = Color(0xFF555555);

  // Border
  static const Color border = Color(0xFF555555);
  static const Color borderActive = Color(0xFFB1ED01);

  // Status (legacy compat)
  static const Color warning = Color(0xFFF6531F);
  static const Color success = Color(0xFFB1ED01);
}
