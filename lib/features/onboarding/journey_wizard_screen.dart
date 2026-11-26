import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers/app_providers.dart';
import '../../application/providers/wizard_draft_provider.dart';
import '../../core/theme/finishx_colors.dart';
import '../../core/theme/finishx_spacing.dart';
import '../../core/widgets/finishx_buttons.dart';
import '../../core/widgets/finishx_card.dart';
import '../../core/widgets/finishx_progress.dart';
import 'widgets/wizard_steps.dart';

class JourneyWizardScreen extends ConsumerStatefulWidget {
  const JourneyWizardScreen({super.key, this.isQueueMode = false});

  final bool isQueueMode;

  @override
  ConsumerState<JourneyWizardScreen> createState() =>
      _JourneyWizardScreenState();
}

class _JourneyWizardScreenState extends ConsumerState<JourneyWizardScreen> {
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hasOpen = ref.read(journeyWorkspaceProvider).hasOpenJourney;
      final effectiveQueue = widget.isQueueMode || hasOpen;
      ref
          .read(journeyWizardProvider.notifier)
          .reset(isQueueMode: effectiveQueue);
    });
  }

  Future<void> _submitWizard() async {
    final draft = ref.read(journeyWizardProvider);
    if (!draft.canContinueFromStep(6)) return;

    setState(() => _isSaving = true);
    try {
      final workspaceCtrl = ref.read(journeyWorkspaceProvider.notifier);
      final hasOpen = ref.read(journeyWorkspaceProvider).hasOpenJourney;

      if (draft.isQueueMode || hasOpen) {
        await workspaceCtrl.enqueueFutureJourney(
          name: draft.journeyName,
          category: draft.category,
          resource: draft.learningResource,
          plannedStartDate: draft.startDate,
          targetCompletionDate: draft.targetCompletionDate,
          commitmentDays: draft.orderedCommitmentDays,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '"${draft.journeyName.trim()}" added to your Journey Queue.',
            ),
          ),
        );
        context.go('/queue');
      } else {
        await workspaceCtrl.createAndSignJourney(
          name: draft.journeyName,
          category: draft.category,
          resource: draft.learningResource,
          startDate: draft.startDate,
          targetCompletionDate: draft.targetCompletionDate,
          commitmentDays: draft.orderedCommitmentDays,
        );
        if (!mounted) return;
        context.go('/group-welcome');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(journeyWizardProvider);
    final notifier = ref.read(journeyWizardProvider.notifier);
    final canContinue = draft.canContinueFromStep(draft.stepIndex);
    final stepFraction = (draft.stepIndex + 1) / 7.0;

    final stepTitle = switch (draft.stepIndex) {
      0 => 'Create Your Journey',
      1 => 'Choose Category',
      2 => 'Learning Resource',
      3 => 'Journey Timeline',
      4 => 'Commitment Days',
      5 => 'Commitment Schedule',
      _ => 'Review & Sign',
    };

    final stepContent = switch (draft.stepIndex) {
      0 => const WizardStepName(),
      1 => const WizardStepCategory(),
      2 => const WizardStepResource(),
      3 => const WizardStepTimeline(),
      4 => const WizardStepDays(),
      5 => const WizardStepSchedule(),
      _ => const WizardStepConfirmation(),
    };

    return Scaffold(
      backgroundColor: FinishXColors.darkBg,
      appBar: AppBar(
        backgroundColor: FinishXColors.darkBg,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: Icon(
              draft.stepIndex == 0
                  ? Icons.close_rounded
                  : Icons.arrow_back_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              if (draft.stepIndex > 0) {
                notifier.previousStep();
              } else if (context.canPop()) {
                context.pop();
              } else {
                final hasOpen = ref
                    .read(journeyWorkspaceProvider)
                    .hasOpenJourney;
                context.go(hasOpen ? '/home' : '/welcome');
              }
            },
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stepTitle,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              'Step ${draft.stepIndex + 1} of 7',
              style: const TextStyle(
                fontSize: 12,
                color: FinishXColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            ResponsiveContainer(
              padding: const EdgeInsets.fromLTRB(
                FinishXSpacing.lg,
                4,
                FinishXSpacing.lg,
                FinishXSpacing.md,
              ),
              child: FinishXProgressBar(
                value: stepFraction,
                height: 4,
                trackColor: FinishXColors.cardSurfaceLight,
                progressColor: FinishXColors.kineticMint,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: FinishXSpacing.xxl),
                child: ResponsiveContainer(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: KeyedSubtree(
                      key: ValueKey(draft.stepIndex),
                      child: stepContent,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: FinishXColors.darkBg,
                border: Border(
                  top: BorderSide(color: FinishXColors.cardBorder),
                ),
              ),
              child: SafeArea(
                top: false,
                child: ResponsiveContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FinishXSpacing.lg,
                    vertical: FinishXSpacing.md,
                  ),
                  child: Row(
                    children: [
                      if (draft.stepIndex > 0) ...[
                        Expanded(
                          flex: 2,
                          child: FinishXSecondaryButton(
                            label: 'Back',
                            onPressed: _isSaving ? null : notifier.previousStep,
                          ),
                        ),
                        const SizedBox(width: FinishXSpacing.sm),
                      ],
                      Expanded(
                        flex: 3,
                        child: FinishXPrimaryButton(
                          label: draft.stepIndex == 6
                              ? (draft.isQueueMode
                                    ? 'Save to Journey Queue'
                                    : 'Sign Commitment')
                              : 'Continue',
                          useMintFill: true,
                          icon: draft.stepIndex == 6
                              ? Icons.draw_rounded
                              : Icons.arrow_forward_rounded,
                          isLoading: _isSaving,
                          onPressed: canContinue
                              ? () {
                                  if (draft.stepIndex < 6) {
                                    notifier.nextStep();
                                  } else {
                                    _submitWizard();
                                  }
                                }
                              : null,
                        ),
                      ),
                    ],
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
