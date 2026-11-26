import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers/app_providers.dart';
import '../../core/theme/finishx_colors.dart';
import '../../core/theme/finishx_spacing.dart';
import '../../core/widgets/finishx_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.94,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _bootAndRoute();
  }

  Future<void> _bootAndRoute() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final auth = ref.read(authControllerProvider);
    if (!auth.isAuthenticated) {
      context.go('/welcome');
      return;
    }

    await ref.read(journeyWorkspaceProvider.notifier).reconcileTimeline();
    if (!mounted) return;

    final workspace = ref.read(journeyWorkspaceProvider);
    final archives = ref.read(archiveQueueControllerProvider).archives;
    final queue = ref.read(archiveQueueControllerProvider).queue;

    if (workspace.activeInProgressSession != null) {
      context.go('/focus');
    } else if (workspace.hasOpenJourney ||
        archives.isNotEmpty ||
        queue.isNotEmpty) {
      context.go('/home');
    } else {
      context.go('/wizard');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FinishXColors.forestInk,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Padding(
                padding: const EdgeInsets.all(FinishXSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FinishXLogo(
                      symbolSize: 64,
                      fontSize: 34,
                      showTagline: true,
                      onDarkBackground: true,
                      axis: Axis.vertical,
                    ),
                    const SizedBox(height: FinishXSpacing.xxl),
                    SizedBox(
                      width: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          backgroundColor: FinishXColors.pureSurface.withValues(
                            alpha: 0.14,
                          ),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            FinishXColors.kineticMint,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
