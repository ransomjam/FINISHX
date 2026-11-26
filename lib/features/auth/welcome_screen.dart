import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/finishx_colors.dart';
import '../../core/theme/finishx_spacing.dart';
import '../../core/widgets/finishx_buttons.dart';
import '../../core/widgets/finishx_card.dart';
import '../../core/widgets/finishx_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: FinishXColors.darkBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: ResponsiveContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FinishXSpacing.xl,
                    vertical: FinishXSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top wordmark
                      const FinishXLogo(
                        symbolSize: 34,
                        fontSize: 22,
                        onDarkBackground: true,
                      ),
                      const SizedBox(height: FinishXSpacing.lg),

                      // Headlines matching mockup
                      Column(
                        children: [
                          Text(
                            'You have something to finish.',
                            textAlign: TextAlign.center,
                            style: textTheme.displayLarge?.copyWith(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: FinishXColors.textPrimary,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: FinishXSpacing.sm),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Turn your ambitions into commitments. Build consistency. Finish what you start.',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: FinishXColors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: FinishXSpacing.md),

                      // Hiker on mountain artwork from the mockup!
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Image.asset(
                              'assets/images/welcome_hiker.jpg',
                              height: 250,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    FinishXColors.darkBg.withValues(
                                      alpha: 0.85,
                                    ),
                                    FinishXColors.darkBg,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: FinishXSpacing.lg),

                      // Buttons
                      Column(
                        children: [
                          FinishXPrimaryButton(
                            label: 'Start Your Journey',
                            suffixIcon: Icons.arrow_forward_rounded,
                            useMintFill: true,
                            onPressed: () => context.push('/auth?intent=start'),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () =>
                                context.push('/auth?intent=signin'),
                            child: Text(
                              'Sign In',
                              style: textTheme.labelLarge?.copyWith(
                                color: FinishXColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
