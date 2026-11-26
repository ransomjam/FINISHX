import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'finishx_colors.dart';
import 'finishx_spacing.dart';
import 'finishx_typography.dart';

/// FinishX Material 3 Theme customized for the Forest Ink & Kinetic Mint dark identity.
abstract final class FinishXTheme {
  static ThemeData get lightTheme {
    final textTheme = FinishXTypography.buildTextTheme();

    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: FinishXColors.kineticMint,
      onPrimary: FinishXColors.darkBg,
      primaryContainer: FinishXColors.deepSpruce,
      onPrimaryContainer: FinishXColors.textPrimary,
      secondary: FinishXColors.kineticMint,
      onSecondary: FinishXColors.darkBg,
      secondaryContainer: FinishXColors.cardSurfaceLight,
      onSecondaryContainer: FinishXColors.textPrimary,
      tertiary: FinishXColors.kineticMint,
      onTertiary: FinishXColors.darkBg,
      tertiaryContainer: FinishXColors.mintSurface,
      onTertiaryContainer: FinishXColors.kineticMint,
      error: FinishXColors.mutedBrick,
      onError: FinishXColors.textPrimary,
      errorContainer: FinishXColors.brickSurface,
      onErrorContainer: FinishXColors.textPrimary,
      surface: FinishXColors.cardSurface,
      onSurface: FinishXColors.textPrimary,
      onSurfaceVariant: FinishXColors.textSecondary,
      outline: FinishXColors.cardBorder,
      outlineVariant: FinishXColors.cardBorder,
      shadow: Colors.black45,
      scrim: Colors.black87,
      inverseSurface: FinishXColors.textPrimary,
      onInverseSurface: FinishXColors.darkBg,
      inversePrimary: FinishXColors.deepSpruce,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: FinishXColors.darkBg,
      textTheme: textTheme,
      fontFamily: FinishXTypography.bodyFont,
      appBarTheme: AppBarTheme(
        backgroundColor: FinishXColors.darkBg,
        foregroundColor: FinishXColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: textTheme.headlineMedium,
        iconTheme: const IconThemeData(
          color: FinishXColors.textPrimary,
          size: 22,
        ),
      ),
      cardTheme: CardThemeData(
        color: FinishXColors.cardSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FinishXSpacing.radiusLg),
          side: const BorderSide(color: FinishXColors.cardBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: FinishXColors.cardBorder,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FinishXColors.cardSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: FinishXSpacing.md,
          vertical: FinishXSpacing.md,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: FinishXColors.textMuted,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: FinishXColors.textSecondary,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: FinishXColors.mutedBrick,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FinishXSpacing.radiusMd),
          borderSide: const BorderSide(color: FinishXColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FinishXSpacing.radiusMd),
          borderSide: const BorderSide(color: FinishXColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FinishXSpacing.radiusMd),
          borderSide: const BorderSide(
            color: FinishXColors.kineticMint,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FinishXSpacing.radiusMd),
          borderSide: const BorderSide(
            color: FinishXColors.mutedBrick,
            width: 1.4,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FinishXSpacing.radiusMd),
          borderSide: const BorderSide(
            color: FinishXColors.mutedBrick,
            width: 1.8,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FinishXColors.kineticMint,
          foregroundColor: FinishXColors.darkBg,
          disabledBackgroundColor: FinishXColors.cardSurfaceLight,
          disabledForegroundColor: FinishXColors.textMuted,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(
            horizontal: FinishXSpacing.xl,
            vertical: FinishXSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FinishXSpacing.radiusPill),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontFamily: FinishXTypography.headingFont,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FinishXColors.textPrimary,
          backgroundColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(
            horizontal: FinishXSpacing.xl,
            vertical: FinishXSpacing.md,
          ),
          side: const BorderSide(color: FinishXColors.cardBorder, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FinishXSpacing.radiusPill),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontFamily: FinishXTypography.headingFont,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FinishXColors.kineticMint,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FinishXSpacing.radiusSm),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: FinishXColors.cardSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FinishXSpacing.radiusXl),
        ),
        titleTextStyle: textTheme.headlineMedium,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: FinishXColors.cardSurface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: FinishXColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(FinishXSpacing.radiusXl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: FinishXColors.cardSurfaceLight,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: FinishXColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FinishXSpacing.radiusMd),
          side: const BorderSide(color: FinishXColors.cardBorder),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: FinishXColors.cardSurface,
        selectedColor: FinishXColors.kineticMint,
        secondarySelectedColor: FinishXColors.kineticMint,
        disabledColor: FinishXColors.cardSurfaceLight,
        side: const BorderSide(color: FinishXColors.cardBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FinishXSpacing.radiusPill),
        ),
        labelStyle: textTheme.bodyMedium!.copyWith(
          color: FinishXColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: textTheme.bodyMedium!.copyWith(
          color: FinishXColors.darkBg,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
