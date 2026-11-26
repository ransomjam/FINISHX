import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers/app_providers.dart';
import '../../core/theme/finishx_colors.dart';
import '../../core/theme/finishx_spacing.dart';
import '../../core/widgets/finishx_buttons.dart';
import '../../core/widgets/finishx_card.dart';
import '../../core/widgets/finishx_progress.dart';
import '../../domain/enums/app_enums.dart';

class SessionReflectionScreen extends ConsumerStatefulWidget {
  const SessionReflectionScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<SessionReflectionScreen> createState() =>
      _SessionReflectionScreenState();
}

class _SessionReflectionScreenState
    extends ConsumerState<SessionReflectionScreen> {
  SessionFeeling? _selected;

  Future<void> _selectAndRecord(SessionFeeling feeling) async {
    if (_selected != null) return;
    setState(() => _selected = feeling);
    await ref
        .read(journeyWorkspaceProvider.notifier)
        .recordReflection(sessionId: widget.sessionId, feeling: feeling);
    if (!mounted) return;
    context.go('/journey-update?sessionId=${widget.sessionId}');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: FinishXSpacing.xxl),
          child: ResponsiveContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FinishXBadge.mint(
                  'SESSION COMPLETE',
                  icon: Icons.check_circle_rounded,
                ),
                const SizedBox(height: FinishXSpacing.lg),
                Text(
                  'How did today\'s session feel?',
                  style: textTheme.displaySmall,
                ),
                const SizedBox(height: FinishXSpacing.xs),
                Text(
                  'Select one option to record your reflection.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: FinishXColors.carbonSecondary,
                  ),
                ),
                const SizedBox(height: FinishXSpacing.xl),
                ...SessionFeeling.values.map(
                  (feeling) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FinishXSelectableTile(
                      title: feeling.label,
                      subtitle: feeling.subtitle,
                      leadingIcon: feeling.icon,
                      selected: _selected == feeling,
                      onTap: () => _selectAndRecord(feeling),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
