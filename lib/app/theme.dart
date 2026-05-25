import 'package:flutter/material.dart';

class KenkoColors {
  static const rawBlack = Color(0xFF101510);
  static const leaf = Color(0xFF5E9B56);
  static const moss = Color(0xFF2E6B45);
  static const cream = Color(0xFFF6F2E7);
  static const harvest = Color(0xFFF2C35B);
  static const flash = Color(0xFFFF6048);
  static const soil = Color(0xFF6E4B32);
}

ThemeData buildKenkoTheme() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: KenkoColors.leaf,
      brightness: Brightness.dark,
      surface: KenkoColors.rawBlack,
    ),
    useMaterial3: true,
  );

  return base.copyWith(
    scaffoldBackgroundColor: KenkoColors.rawBlack,
    textTheme: base.textTheme.apply(
      bodyColor: KenkoColors.cream,
      displayColor: KenkoColors.cream,
    ),
  );
}
