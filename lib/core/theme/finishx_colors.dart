import 'package:flutter/material.dart';

/// FinishX Brand Visual Identity — Deep Forest Ink & Kinetic Mint.
///
/// Exactly matching the design specification:
/// Deep dark forest canvas (#091815), glassmorphic dark emerald containers (#132A24),
/// glowing Kinetic Mint accents (#72E3B6), and crisp white/sage typography.
abstract final class FinishXColors {
  /// Deep dark forest canvas
  static const Color darkBg = Color(0xFF091815);
  static const Color darkBgSecondary = Color(0xFF0D211C);

  /// Elevated card & container surfaces
  static const Color cardSurface = Color(0xFF132A24);
  static const Color cardSurfaceLight = Color(0xFF1A3830);
  static const Color cardBorder = Color(0xFF1F443B);

  /// Primary brand anchors
  static const Color forestInk = Color(0xFF091815);
  static const Color deepSpruce = Color(0xFF183C33);

  /// Kinetic Mint highlights, active states, progress, primary CTAs
  static const Color kineticMint = Color(0xFF72E3B6);
  static const Color kineticMintLight = Color(0xFF9CF4D3);
  static const Color mintSurface = Color(0xFF183E34);

  /// Typography
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8FA9A1);
  static const Color textMuted = Color(0xFF5E7B73);

  /// Missed-session / warning states
  static const Color mutedBrick = Color(0xFFE07A6D);
  static const Color brickSurface = Color(0xFF2C1A17);

  // Backward-compatibility aliases:
  static const Color warmChalk = darkBg;
  static const Color pureSurface = cardSurface;
  static const Color softSage = cardSurfaceLight;
  static const Color sageBorder = cardBorder;
  static const Color carbon = textPrimary;
  static const Color carbonSecondary = textSecondary;
  static const Color carbonMuted = textMuted;
  static const Color chalkSubtle = darkBgSecondary;
}
