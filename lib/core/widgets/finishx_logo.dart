import 'package:flutter/material.dart';
import '../theme/finishx_colors.dart';
import '../theme/finishx_typography.dart';

/// Custom FinishX Symbol & Wordmark.
///
/// The FX mark depicts an architectural 'X' formed from two distinct paths
/// intersecting and converging towards a shared Kinetic Mint horizon point,
/// symbolising different personal journeys leading to completion.
class FinishXLogo extends StatelessWidget {
  const FinishXLogo({
    super.key,
    this.symbolSize = 36,
    this.fontSize = 24,
    this.showWordmark = true,
    this.showTagline = false,
    this.onDarkBackground = false,
    this.axis = Axis.horizontal,
  });

  final double symbolSize;
  final double fontSize;
  final bool showWordmark;
  final bool showTagline;
  final bool onDarkBackground;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final symbol = FinishXSymbol(size: symbolSize, inverted: onDarkBackground);

    if (!showWordmark) return symbol;

    final primaryTextColor = onDarkBackground
        ? FinishXColors.pureSurface
        : FinishXColors.forestInk;
    final accentColor = onDarkBackground
        ? FinishXColors.kineticMint
        : FinishXColors.deepSpruce;

    final wordmark = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: axis == Axis.vertical
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontFamily: FinishXTypography.headingFont,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              height: 1.05,
              color: primaryTextColor,
            ),
            children: [
              const TextSpan(text: 'Finish'),
              TextSpan(
                text: 'X',
                style: TextStyle(
                  color: onDarkBackground
                      ? FinishXColors.kineticMint
                      : accentColor,
                ),
              ),
            ],
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            'ONE JOURNEY. FULL FOCUS.',
            style: TextStyle(
              fontFamily: FinishXTypography.bodyFont,
              fontSize: (fontSize * 0.42).clamp(9.5, 12.0),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.6,
              color: onDarkBackground
                  ? FinishXColors.softSage.withValues(alpha: 0.85)
                  : FinishXColors.carbonSecondary,
            ),
          ),
        ],
      ],
    );

    if (axis == Axis.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          symbol,
          SizedBox(height: symbolSize * 0.32),
          wordmark,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        symbol,
        SizedBox(width: symbolSize * 0.32),
        wordmark,
      ],
    );
  }
}

/// Vector-drawn FX mark with two intersecting paths converging at a completion node.
class FinishXSymbol extends StatelessWidget {
  const FinishXSymbol({super.key, this.size = 36, this.inverted = false});

  final double size;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: inverted
            ? FinishXColors.deepSpruce.withValues(alpha: 0.65)
            : FinishXColors.forestInk,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: inverted
            ? Border.all(
                color: FinishXColors.kineticMint.withValues(alpha: 0.35),
                width: 1.2,
              )
            : null,
      ),
      child: CustomPaint(painter: _ConvergingPathsPainter()),
    );
  }
}

class _ConvergingPathsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = (w * 0.088).clamp(2.2, 5.5);

    // Secondary journey path: starts top-left, sweeps down-right, then rises toward apex
    final secondaryPaint = Paint()
      ..color = FinishXColors.pureSurface.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Primary commitment path: starts bottom-left, ascends decisively to the top-right apex
    final primaryPaint = Paint()
      ..color = FinishXColors.kineticMint
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 1.06
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Path A: Top-left to bottom-right, with an upward inflection converging toward right horizon
    final pathA = Path()
      ..moveTo(w * 0.24, h * 0.26)
      ..cubicTo(w * 0.42, h * 0.38, w * 0.52, h * 0.64, w * 0.74, h * 0.73);

    // Path B: Bottom-left ascending cleanly across Path A to the shared completion endpoint
    final pathB = Path()
      ..moveTo(w * 0.24, h * 0.74)
      ..cubicTo(w * 0.44, h * 0.62, w * 0.54, h * 0.38, w * 0.75, h * 0.27);

    // Subtle convergence bridge connecting lower-right arm toward the completion node
    final convergencePaint = Paint()
      ..color = FinishXColors.kineticMint.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.65
      ..strokeCap = StrokeCap.round;

    final convergenceBridge = Path()
      ..moveTo(w * 0.74, h * 0.73)
      ..quadraticBezierTo(w * 0.80, h * 0.50, w * 0.75, h * 0.27);

    canvas.drawPath(convergenceBridge, convergencePaint);
    canvas.drawPath(pathA, secondaryPaint);
    canvas.drawPath(pathB, primaryPaint);

    // Completion endpoint node at top-right convergence
    final nodePaint = Paint()
      ..color = FinishXColors.kineticMint
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.75, h * 0.27), stroke * 0.72, nodePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
