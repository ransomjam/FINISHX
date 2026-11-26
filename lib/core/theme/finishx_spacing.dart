import 'package:flutter/material.dart';
import 'finishx_colors.dart';

/// Centralised spacing, corner radius, elevation, and layout tokens.
abstract final class FinishXSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // Radii
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 26;
  static const double radiusPill = 999;

  // Responsive max widths
  static const double maxMobileContentWidth = 620;
  static const double maxTabletContentWidth = 840;

  // Controlled subtle shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: FinishXColors.forestInk.withValues(alpha: 0.045),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: FinishXColors.forestInk.withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get heroShadow => [
    BoxShadow(
      color: FinishXColors.forestInk.withValues(alpha: 0.16),
      blurRadius: 26,
      offset: const Offset(0, 10),
    ),
  ];
}
