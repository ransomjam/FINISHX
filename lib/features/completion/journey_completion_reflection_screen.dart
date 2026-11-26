import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers/app_providers.dart';
import '../../core/theme/finishx_colors.dart';
import '../../core/theme/finishx_spacing.dart';
import '../../core/widgets/finishx_buttons.dart';
import '../../core/widgets/finishx_card.dart';
import '../../core/widgets/finishx_empty_state.dart';
import '../../domain/enums/app_enums.dart';

class JourneyCompletionReflectionScreen extends ConsumerStatefulWidget {
  const JourneyCompletionReflectionScreen({super.key});

  @override
  ConsumerState<JourneyCompletionReflectionScreen> createState() =>
      _JourneyCompletionReflectionScreenState();
}

class _JourneyCompletionReflectionScreenState
    extends ConsumerState<JourneyCompletionReflectionScreen> {
  final _formKey = GlobalKey<FormState>();
  CompletionOutcome _outcome = CompletionOutcome.yes;
  final _proudController = TextEditingController();
  final _lessonController = TextEditingController();
  bool _isCompleting = false;

  @override
  void dispose() {
    _proudController.dispose();
    _lessonController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndComplete(String journeyName) async {
    if (_formKey.currentState?.validate() != true) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete this journey?'),
        content: Text(
          'Confirming completion permanently archives "$journeyName" with your reflections and frees your focus for your next journey.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(140, 44)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm Completion'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCompleting = true);
    try {
      await ref
          .read(journeyWorkspaceProvider.notifier)
          .completeJourney(
            outcome: _outcome,
            proudAccomplishment: _proudController.text,
            biggestLesson: _lessonController.text,
          );
      if (!mounted) return;
      context.go('/journey-completed');
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final journey = ref.watch(journeyWorkspaceProvider).openJourney;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Completion Reflection')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: FinishXSpacing.xxl),
          child: ResponsiveContainer(
            child: journey == null
                ? const FinishXEmptyState(
                    icon: Icons.emoji_flags_rounded,
                    title: 'No active journey to complete',
                    description: 'Your completed journeys live in the Archive.',
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Did you achieve your journey?',
                          style: textTheme.displaySmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Reflect honestly on "${journey.name}" before closing this chapter.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: FinishXColors.carbonSecondary,
                          ),
                        ),
                        const SizedBox(height: FinishXSpacing.lg),
                        ...CompletionOutcome.values.map(
                          (option) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: FinishXSelectableTile(
                              title: option.label,
                              subtitle: option.subtitle,
                              selected: _outcome == option,
                              onTap: () => setState(() => _outcome = option),
                            ),
                          ),
                        ),
                        const SizedBox(height: FinishXSpacing.lg),
                        Text(
                          'What accomplishment are you most proud of?',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _proudController,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText:
                                'e.g. Built three end-to-end projects and never missed two sessions in a row.',
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                              ? 'Capture what you are most proud of.'
                              : null,
                        ),
                        const SizedBox(height: FinishXSpacing.md),
                        Text(
                          'What is the biggest lesson you learned?',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _lessonController,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText:
                                'e.g. Protecting a fixed evening slot works far better than waiting for motivation.',
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                              ? 'Record your biggest lesson from this journey.'
                              : null,
                        ),
                        const SizedBox(height: FinishXSpacing.xl),
                        FinishXPrimaryButton(
                          label: 'Complete Journey',
                          useMintFill: true,
                          isLoading: _isCompleting,
                          icon: Icons.verified_rounded,
                          onPressed: () => _confirmAndComplete(journey.name),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
