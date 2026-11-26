import 'package:flutter/material.dart';
import '../theme/finishx_colors.dart';
import '../theme/finishx_spacing.dart';

enum FinishXCardVariant {
  surface,
  heroForest,
  softSage,
  supportiveBrick,
  mintTint,
}

/// Reusable elevated container following FinishX surface and border rules.
class FinishXCard extends StatelessWidget {
  const FinishXCard({
    super.key,
    required this.child,
    this.variant = FinishXCardVariant.surface,
    this.padding = const EdgeInsets.all(FinishXSpacing.lg),
    this.onTap,
    this.borderRadius = FinishXSpacing.radiusLg,
  });

  final Widget child;
  final FinishXCardVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final (bgColor, borderColor, shadows) = switch (variant) {
      FinishXCardVariant.surface => (
        FinishXColors.pureSurface,
        FinishXColors.softSage,
        FinishXSpacing.cardShadow,
      ),
      FinishXCardVariant.heroForest => (
        FinishXColors.forestInk,
        FinishXColors.deepSpruce,
        FinishXSpacing.heroShadow,
      ),
      FinishXCardVariant.softSage => (
        FinishXColors.softSage.withValues(alpha: 0.55),
        FinishXColors.sageBorder,
        const <BoxShadow>[],
      ),
      FinishXCardVariant.supportiveBrick => (
        FinishXColors.brickSurface,
        FinishXColors.mutedBrick.withValues(alpha: 0.35),
        const <BoxShadow>[],
      ),
      FinishXCardVariant.mintTint => (
        FinishXColors.mintSurface,
        FinishXColors.kineticMint.withValues(alpha: 0.55),
        const <BoxShadow>[],
      ),
    };

    final radius = BorderRadius.circular(borderRadius);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
        border: Border.all(color: borderColor, width: 1),
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Centered responsive wrapper ensuring comfortable widths on phones and tablets.
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = FinishXSpacing.maxMobileContentWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: FinishXSpacing.lg),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
