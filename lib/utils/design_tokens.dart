import 'package:flutter/material.dart';

/// Design tokens (approximate values inspired by Figma palette)
class DesignTokens {
  // Primary purple accent
  static const Color primary = Color(0xFF7C4DFF);
  static const Color primaryVariant = Color(0xFF5A3E9E);

  // Backgrounds
  static const Color bg = Color(0xFF0F1221);
  static const Color surface = Color(0xFF141625);

  // Neutrals
  static const Color neutralHigh = Color(0xFFECECF6);
  static const Color neutralLow = Color(0xFF9AA0B4);

  // Success / error
  static const Color success = Color(0xFF2DBE6A);
  static const Color danger = Color(0xFFEF5350);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C4DFF), Color(0xFF5A3E9E)],
  );
}
