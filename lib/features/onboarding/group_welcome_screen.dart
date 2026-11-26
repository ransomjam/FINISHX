import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers/app_providers.dart';
import '../../core/theme/finishx_colors.dart';
import '../../core/theme/finishx_spacing.dart';
import '../../core/widgets/finishx_buttons.dart';
import '../../core/widgets/finishx_card.dart';

/// Group Welcome Screen — exact reproduction of Screen 7 in media_1795599304928_c0a38770.jpg
class GroupWelcomeScreen extends ConsumerWidget {
  const GroupWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupControllerProvider).group;
    final textTheme = Theme.of(context).textTheme;

    if (group == null) {
      return Scaffold(
        backgroundColor: FinishXColors.darkBg,
        body: SafeArea(
          child: Center(
            child: FinishXPrimaryButton(
              label: 'Continue to Dashboard',
              compact: true,
              onPressed: () => context.go('/home'),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: FinishXColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: ResponsiveContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FinishXSpacing.xl,
                    vertical: FinishXSpacing.xxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: FinishXSpacing.xl),

                      // Emerald circle emblem with group avatars icon
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF13382D),
                          border: Border.all(
                            color: FinishXColors.kineticMint.withValues(
                              alpha: 0.4,
                            ),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: FinishXColors.kineticMint.withValues(
                                alpha: 0.2,
                              ),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.groups_2_rounded,
                          color: FinishXColors.kineticMint,
                          size: 44,
                        ),
                      ),

                      const SizedBox(height: FinishXSpacing.xl),

                      Text(
                        'Welcome to\n${group.name}',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),

                      const SizedBox(height: FinishXSpacing.xxl),

                      // 3 stats columns: 8 Members, League II, 81% Group Health
                      FinishXCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatColumn(
                                icon: Icons.person_outline_rounded,
                                label: 'Members',
                                value: '${group.memberCount}',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 38,
                              color: FinishXColors.cardBorder,
                            ),
                            const Expanded(
                              child: _StatColumn(
                                icon: Icons.military_tech_outlined,
                                label: 'League',
                                value: 'League II',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 38,
                              color: FinishXColors.cardBorder,
                            ),
                            const Expanded(
                              child: _StatColumn(
                                icon: Icons.bar_chart_rounded,
                                label: 'Group Health',
                                value: '81%',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: FinishXSpacing.xl),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "You're now part of a supportive community, focused on showing up and finishing together.",
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: FinishXColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom CTA
            ResponsiveContainer(
              padding: const EdgeInsets.fromLTRB(
                FinishXSpacing.xl,
                FinishXSpacing.sm,
                FinishXSpacing.xl,
                FinishXSpacing.lg,
              ),
              child: FinishXPrimaryButton(
                label: 'Continue to Dashboard',
                useMintFill: true,
                suffixIcon: Icons.arrow_forward_rounded,
                onPressed: () => context.go('/home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: FinishXColors.kineticMint),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: FinishXColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
