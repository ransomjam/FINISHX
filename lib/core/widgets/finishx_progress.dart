import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/finishx_colors.dart';
import '../theme/finishx_spacing.dart';
import '../theme/finishx_typography.dart';

/// Smooth linear progress bar styled with Kinetic Mint and Soft Sage.
class FinishXProgressBar extends StatelessWidget {
  const FinishXProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.trackColor,
    this.progressColor = FinishXColors.kineticMint,
  });

  /// Normalized value between 0.0 and 1.0.
  final double value;
  final double height;
  final Color? trackColor;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(FinishXSpacing.radiusPill),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: trackColor ?? FinishXColors.softSage),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clamped,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(
                    FinishXSpacing.radiusPill,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular consistency ring with centre metric label.
class FinishXConsistencyRing extends StatelessWidget {
  const FinishXConsistencyRing({
    super.key,
    required this.percentage,
    this.size = 76,
    this.strokeWidth = 7,
    this.onDark = false,
    this.subtitle,
  });

  /// Percentage from 0 to 100.
  final int percentage;
  final double size;
  final double strokeWidth;
  final bool onDark;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final normalized = (percentage / 100.0).clamp(0.0, 1.0);
    final textColor = onDark
        ? FinishXColors.pureSurface
        : FinishXColors.forestInk;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: normalized,
              strokeWidth: strokeWidth,
              trackColor: onDark
                  ? FinishXColors.pureSurface.withValues(alpha: 0.14)
                  : FinishXColors.softSage,
              progressColor: FinishXColors.kineticMint,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percentage%',
                style: TextStyle(
                  fontFamily: FinishXTypography.headingFont,
                  fontSize: size * 0.24,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontFamily: FinishXTypography.bodyFont,
                    fontSize: size * 0.125,
                    fontWeight: FontWeight.w500,
                    color: onDark
                        ? FinishXColors.softSage
                        : FinishXColors.carbonSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final arcPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}

/// Compact semantic badge pill for statuses, leagues, and categories.
class FinishXBadge extends StatelessWidget {
  const FinishXBadge({
    super.key,
    required this.label,
    this.backgroundColor = FinishXColors.softSage,
    this.foregroundColor = FinishXColors.forestInk,
    this.icon,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;

  factory FinishXBadge.mint(String label, {IconData? icon}) => FinishXBadge(
    label: label,
    backgroundColor: FinishXColors.kineticMint,
    foregroundColor: FinishXColors.forestInk,
    icon: icon,
  );

  factory FinishXBadge.forest(String label, {IconData? icon}) => FinishXBadge(
    label: label,
    backgroundColor: FinishXColors.forestInk,
    foregroundColor: FinishXColors.pureSurface,
    icon: icon,
  );

  factory FinishXBadge.brick(String label, {IconData? icon}) => FinishXBadge(
    label: label,
    backgroundColor: FinishXColors.brickSurface,
    foregroundColor: FinishXColors.mutedBrick,
    icon: icon,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(FinishXSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foregroundColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: FinishXTypography.bodyFont,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
