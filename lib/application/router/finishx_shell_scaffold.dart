import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/finishx_colors.dart';
import '../../core/theme/finishx_spacing.dart';
import '../../core/theme/finishx_typography.dart';

/// Custom four-item bottom navigation shell matching the Forest & Kinetic Mint identity:
/// 1. Home
/// 2. Journey
/// 3. Group
/// 4. Archive
class FinishXShellScaffold extends StatelessWidget {
  const FinishXShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    _NavItem(
      label: 'Home',
      inactiveIcon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _NavItem(
      label: 'Journey',
      inactiveIcon: Icons.auto_stories_outlined,
      activeIcon: Icons.auto_stories_rounded,
    ),
    _NavItem(
      label: 'Group',
      inactiveIcon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
    ),
    _NavItem(
      label: 'Archive',
      inactiveIcon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: FinishXColors.darkBg,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: FinishXColors.darkBg,
          border: Border(
            top: BorderSide(color: FinishXColors.cardBorder, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FinishXSpacing.sm,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_destinations.length, (index) {
                  final item = _destinations[index];
                  final isSelected = index == currentIndex;
                  return Expanded(
                    child: Semantics(
                      selected: isSelected,
                      button: true,
                      label: item.label,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          FinishXSpacing.radiusMd,
                        ),
                        onTap: () {
                          navigationShell.goBranch(
                            index,
                            initialLocation: index == currentIndex,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              FinishXSpacing.radiusMd,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelected
                                    ? item.activeIcon
                                    : item.inactiveIcon,
                                size: 22,
                                color: isSelected
                                    ? FinishXColors.kineticMint
                                    : FinishXColors.textSecondary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: FinishXTypography.headingFont,
                                  fontSize: 11.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? FinishXColors.kineticMint
                                      : FinishXColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.inactiveIcon,
    required this.activeIcon,
  });

  final String label;
  final IconData inactiveIcon;
  final IconData activeIcon;
}
