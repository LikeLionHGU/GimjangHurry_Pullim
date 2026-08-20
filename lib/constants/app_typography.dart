import 'package:flutter/material.dart';

/// 디자인 시스템 타이포그래피 토큰.
/// 네이밍 규칙: {Weight}_{Size}
///   B = Bold (700), SB = SemiBold (600), R = Regular (400)
class AppTypography {
  AppTypography._();

  static const String _fontFamily = 'NotoSansKR';

  // ─── Bold (700) ───────────────────────────────────────────
  static const TextStyle b40 = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 40,
  );

  static const TextStyle b35 = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 35,
  );

  static const TextStyle b32 = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 32,
  );

  static const TextStyle b20 = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 20,
  );

  static const TextStyle b18 = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 18,
  );

  static const TextStyle b16 = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 16,
  );

  // ─── SemiBold (600) ───────────────────────────────────────
  static const TextStyle sb24 = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 24,
  );

  static const TextStyle sb18 = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 18,
  );

  static const TextStyle sb16 = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 16,
  );

  // ─── Regular (400) ────────────────────────────────────────
  static const TextStyle r18 = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 18,
  );

  static const TextStyle r16 = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 16,
  );

  static const TextStyle r14 = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 14,
  );

  static const TextStyle r12 = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 12,
  );
}
