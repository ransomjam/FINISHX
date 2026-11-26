import 'package:flutter/material.dart';
import 'finishx_colors.dart';

/// FinishX Typography System.
///
/// Uses Manrope for display headings and Inter for labels, forms, and body copy.
abstract final class FinishXTypography {
  static const String headingFont = 'Manrope';
  static const String bodyFont = 'Inter';

  static TextTheme buildTextTheme({
    Color textColor = FinishXColors.textPrimary,
  }) {
    const secondary = FinishXColors.textSecondary;

    return const TextTheme(
      displayLarge: TextStyle(
        fontFamily: headingFont,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.9,
        color: FinishXColors.textPrimary,
      ),
      displayMedium: TextStyle(
        fontFamily: headingFont,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.7,
        color: FinishXColors.textPrimary,
      ),
      displaySmall: TextStyle(
        fontFamily: headingFont,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.24,
        letterSpacing: -0.5,
        color: FinishXColors.textPrimary,
      ),
      headlineLarge: TextStyle(
        fontFamily: headingFont,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.28,
        letterSpacing: -0.4,
        color: FinishXColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: headingFont,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.3,
        color: FinishXColors.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontFamily: headingFont,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.35,
        letterSpacing: -0.2,
        color: FinishXColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: headingFont,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: FinishXColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: bodyFont,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: FinishXColors.textPrimary,
      ),
      titleSmall: TextStyle(
        fontFamily: bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.1,
        color: secondary,
      ),
      bodyLarge: TextStyle(
        fontFamily: bodyFont,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: FinishXColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: FinishXColors.textPrimary,
      ),
      bodySmall: TextStyle(
        fontFamily: bodyFont,
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: secondary,
      ),
      labelLarge: TextStyle(
        fontFamily: bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0.1,
        color: FinishXColors.textPrimary,
      ),
      labelMedium: TextStyle(
        fontFamily: bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0.4,
        color: secondary,
      ),
      labelSmall: TextStyle(
        fontFamily: bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.6,
        color: secondary,
      ),
    );
  }
}
