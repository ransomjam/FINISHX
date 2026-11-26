import 'package:flutter/material.dart';
import '../theme/finishx_colors.dart';
import '../theme/finishx_spacing.dart';
import '../theme/finishx_typography.dart';

/// Primary action button — Kinetic Mint pill matching the FinishX mockups.
class FinishXPrimaryButton extends StatelessWidget {
  const FinishXPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.suffixIcon,
    this.isLoading = false,
    this.useMintFill = true,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? suffixIcon;
  final bool isLoading;
  final bool useMintFill;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bgColor = useMintFill
        ? FinishXColors.kineticMint
        : FinishXColors.cardSurfaceLight;
    final fgColor = useMintFill
        ? const Color(0xFF091815)
        : FinishXColors.textPrimary;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        disabledBackgroundColor: FinishXColors.cardSurfaceLight,
        disabledForegroundColor: FinishXColors.textMuted,
        minimumSize: Size(compact ? 0 : double.infinity, compact ? 44 : 52),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? FinishXSpacing.lg : FinishXSpacing.xl,
          vertical: compact ? 10 : FinishXSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FinishXSpacing.radiusPill),
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: fgColor,
              ),
            )
          : Row(
              mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 19, color: fgColor),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: FinishXTypography.headingFont,
                      fontWeight: FontWeight.w700,
                      fontSize: compact ? 14 : 15.5,
                      color: onPressed == null
                          ? FinishXColors.textMuted
                          : fgColor,
                    ),
                  ),
                ),
                if (suffixIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(suffixIcon, size: 19, color: fgColor),
                ],
              ],
            ),
    );
  }
}

/// Secondary outlined pill button.
class FinishXSecondaryButton extends StatelessWidget {
  const FinishXSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isDestructive = false,
    this.onDarkBackground = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isDestructive;
  final bool onDarkBackground;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fgColor = isDestructive
        ? FinishXColors.mutedBrick
        : FinishXColors.textPrimary;
    final borderColor = isDestructive
        ? FinishXColors.mutedBrick.withValues(alpha: 0.5)
        : FinishXColors.cardBorder;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: fgColor,
        backgroundColor: FinishXColors.cardSurfaceLight.withValues(alpha: 0.3),
        minimumSize: Size(compact ? 0 : double.infinity, compact ? 44 : 52),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? FinishXSpacing.lg : FinishXSpacing.xl,
          vertical: compact ? 10 : FinishXSpacing.md,
        ),
        side: BorderSide(color: borderColor, width: 1.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FinishXSpacing.radiusPill),
        ),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: fgColor),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: FinishXTypography.headingFont,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 14 : 15,
                color: fgColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selectable card option used across onboarding, reflections, and dialogs.
class FinishXSelectableTile extends StatelessWidget {
  const FinishXSelectableTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final bgColor = selected
        ? FinishXColors.mintSurface
        : FinishXColors.cardSurface;
    const textColor = FinishXColors.textPrimary;
    const subColor = FinishXColors.textSecondary;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(FinishXSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FinishXSpacing.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: FinishXSpacing.md,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FinishXSpacing.radiusMd),
            border: Border.all(
              color: selected
                  ? FinishXColors.kineticMint
                  : FinishXColors.cardBorder,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: selected
                        ? FinishXColors.kineticMint.withValues(alpha: 0.15)
                        : FinishXColors.cardSurfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    leadingIcon,
                    size: 19,
                    color: selected
                        ? FinishXColors.kineticMint
                        : FinishXColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: subColor),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 21,
                  color: selected
                      ? FinishXColors.kineticMint
                      : FinishXColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
