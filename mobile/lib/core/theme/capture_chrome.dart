import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Visual tokens for the dark camera chrome — theme-independent.
abstract final class CaptureChrome {
  static const accent = DesignTokens.primaryBlue;
  static const accentGlow = Color(0x662563EB);
  static const perfect = Color(0xFF16A34A);
  static const perfectGlow = Color(0x6616A34A);
  static const warning = Color(0xFFF87171);
  static const surfaceGlass = Color(0x990F172A);
  static const iconGlass = Color(0x14FFFFFF);
  static const borderGlass = Color(0x2EFFFFFF);
  static const borderAccent = Color(0x662563EB);
  static const textPrimary = Color(0xFFF8FAFC);
  static const textMuted = Color(0xB3F8FAFC);

  static const primaryGradient = DesignTokens.primaryGradient;
}
