import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers/app_providers.dart';
import '../../application/providers/wizard_draft_provider.dart';
import '../../core/theme/finishx_colors.dart';
import '../../core/theme/finishx_spacing.dart';
import '../../core/widgets/finishx_buttons.dart';
import '../../core/widgets/finishx_card.dart';

/// Journey Completion Screen — exact reproduction of Screen 12 in media_1795599304928_c0a38770.jpg
class JourneyCompletionScreen extends ConsumerStatefulWidget {
  const JourneyCompletionScreen({super.key});

  @override
  ConsumerState<JourneyCompletionScreen> createState() =>
      _JourneyCompletionScreenState();
}

class _JourneyCompletionScreenState
    extends ConsumerState<JourneyCompletionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _haloScale;
  late final Animation<double> _contentOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _haloScale = Tween<double>(
      begin: 0.82,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _contentOpacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final archiveState = ref.watch(archiveQueueControllerProvider);
    final archive =
        archiveState.latestCompletedArchive ??
        (archiveState.archives.isNotEmpty ? archiveState.archives.first : null);
    final textTheme = Theme.of(context).textTheme;

    if (archive == null) {
      return Scaffold(
        backgroundColor: FinishXColors.darkBg,
        body: Center(
          child: FinishXPrimaryButton(
            label: 'View Journey Archive',
            compact: true,
            onPressed: () => context.go('/archive'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: FinishXColors.darkBg,
      body: Stack(
        children: [
          // Subtle confetti decorative particles
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _ConfettiParticlesPainter()),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _contentOpacity,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: FinishXSpacing.xl,
                  vertical: FinishXSpacing.xl,
                ),
                child: ResponsiveContainer(
                  child: Column(
                    children: [
                      const SizedBox(height: FinishXSpacing.lg),

                      // Large mint circular emblem with dark checkmark
                      ScaleTransition(
                        scale: _haloScale,
                        child: Container(
                          width: 88,
                          height: 88,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: FinishXColors.kineticMint,
                            boxShadow: [
                              BoxShadow(
                                color: FinishXColors.kineticMint.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 32,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 48,
                            color: Color(0xFF091815),
                          ),
                        ),
                      ),
                      const SizedBox(height: FinishXSpacing.xl),

                      Text(
                        'Journey Complete',
                        textAlign: TextAlign.center,
                        style: textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: FinishXSpacing.sm),
                      Text(
                        'Congratulations. You honored the commitments you made to yourself.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: FinishXColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: FinishXSpacing.xl),

                      // Main stats card with 2x2 grid
                      FinishXCard(
                        padding: const EdgeInsets.all(FinishXSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: FinishXColors.kineticMint.withValues(
                                      alpha: 0.18,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    archive.journey.category.icon,
                                    color: FinishXColors.kineticMint,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    archive.journey.name,
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // 2x2 Grid stats matching Screen 12 in mockup
                            Row(
                              children: [
                                Expanded(
                                  child: _StatBox(
                                    label: 'Duration',
                                    value: '${archive.durationDays} days',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatBox(
                                    label: 'Sessions',
                                    value: '${archive.completedSessionsCount}',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatBox(
                                    label: 'Consistency',
                                    value: '${archive.consistencyPercentage}%',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatBox(
                                    label: 'Updates',
                                    value: '${archive.updatesCount}',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: FinishXSpacing.xxl),

                      // Outlined button: View Journey Archive
                      FinishXSecondaryButton(
                        label: 'View Journey Archive',
                        onPressed: () => context.go('/archive'),
                      ),
                      const SizedBox(height: 12),

                      // Mint button: Choose Your Next Journey ->
                      FinishXPrimaryButton(
                        label: 'Choose Your Next Journey',
                        suffixIcon: Icons.arrow_forward_rounded,
                        useMintFill: true,
                        onPressed: () {
                          ref
                              .read(journeyWizardProvider.notifier)
                              .reset(isQueueMode: false);
                          context.go('/wizard');
                        },
                      ),
                      const SizedBox(height: FinishXSpacing.lg),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: FinishXColors.cardSurfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: FinishXColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiParticlesPainter extends CustomPainter {
  const _ConfettiParticlesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(42);
    final colors = [
      FinishXColors.kineticMint,
      const Color(0xFFFFB800),
      const Color(0xFFFF5252),
      FinishXColors.textSecondary,
    ];

    for (int i = 0; i < 35; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * (size.height * 0.45);
      final r = 2.0 + rand.nextDouble() * 3.5;
      final paint = Paint()
        ..color = colors[rand.nextInt(colors.length)].withValues(alpha: 0.65)
        ..style = PaintingStyle.fill;

      if (i % 2 == 0) {
        canvas.drawCircle(Offset(x, y), r, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: r * 2, height: r * 1.2),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
