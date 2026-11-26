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

/// Weekly Check-In Screen — exact match to Screen 11 in media_1795599304928_c0a38770.jpg
class WeeklyCheckInScreen extends ConsumerStatefulWidget {
  const WeeklyCheckInScreen({super.key});

  @override
  ConsumerState<WeeklyCheckInScreen> createState() =>
      _WeeklyCheckInScreenState();
}

class _WeeklyCheckInScreenState extends ConsumerState<WeeklyCheckInScreen> {
  final _formKey = GlobalKey<FormState>();
  WeeklyCompletionAnswer _answer = WeeklyCompletionAnswer.yes;
  final _winController = TextEditingController();
  final _challengeController = TextEditingController();
  final _focusController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _winController.dispose();
    _challengeController.dispose();
    _focusController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(journeyWorkspaceProvider.notifier)
          .submitWeeklyCheckIn(
            completedCommitments: _answer,
            biggestWin: _winController.text,
            biggestChallenge: _challengeController.text,
            nextWeekFocus: _focusController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Weekly reflection saved.')));
      _winController.clear();
      _challengeController.clear();
      _focusController.clear();
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(journeyWorkspaceProvider);
    final journey = workspace.openJourney;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: FinishXColors.darkBg,
      appBar: AppBar(
        backgroundColor: FinishXColors.darkBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: FinishXSpacing.xl,
            vertical: FinishXSpacing.sm,
          ),
          child: ResponsiveContainer(
            child: journey == null
                ? const FinishXEmptyState(
                    icon: Icons.auto_stories_outlined,
                    title: 'No active journey',
                    description:
                        'Weekly Sunday check-ins become available once you have an active journey.',
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top green calendar icon in rounded container
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: FinishXColors.cardSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: FinishXColors.kineticMint.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: FinishXColors.kineticMint,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 14),

                        Text(
                          'Weekly Check-In',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Let's reflect on your week. It takes less than a minute.",
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: FinishXColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: FinishXSpacing.xl),

                        // Question 1: Planned commitments
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '1. Did you complete your planned commitments this week?',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 3 horizontal pill options: [Yes] [Partially] [No]
                        Row(
                          children: [
                            _buildChoicePill(
                              label: 'Yes',
                              value: WeeklyCompletionAnswer.yes,
                            ),
                            const SizedBox(width: 8),
                            _buildChoicePill(
                              label: 'Partially',
                              value: WeeklyCompletionAnswer.partially,
                            ),
                            const SizedBox(width: 8),
                            _buildChoicePill(
                              label: 'No',
                              value: WeeklyCompletionAnswer.no,
                            ),
                          ],
                        ),

                        const SizedBox(height: FinishXSpacing.lg),

                        // Question 2: Biggest win
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '2. What was your biggest win?',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _winController,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'e.g. Completed two modules...',
                            hintStyle: const TextStyle(
                              color: FinishXColors.textSecondary,
                            ),
                            filled: true,
                            fillColor: FinishXColors.cardSurface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: FinishXColors.cardBorder,
                              ),
                            ),
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                              ? 'Share even a small win from this week.'
                              : null,
                        ),

                        const SizedBox(height: FinishXSpacing.lg),

                        // Question 3: Challenge
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '3. What challenged you the most?',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _challengeController,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'e.g. Time management...',
                            hintStyle: const TextStyle(
                              color: FinishXColors.textSecondary,
                            ),
                            filled: true,
                            fillColor: FinishXColors.cardSurface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: FinishXColors.cardBorder,
                              ),
                            ),
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                              ? 'Note your main challenge.'
                              : null,
                        ),

                        const SizedBox(height: FinishXSpacing.lg),

                        // Question 4: Focus next week
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '4. What will you focus on next week?',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _focusController,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'e.g. Complete Module 5...',
                            hintStyle: const TextStyle(
                              color: FinishXColors.textSecondary,
                            ),
                            filled: true,
                            fillColor: FinishXColors.cardSurface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: FinishXColors.cardBorder,
                              ),
                            ),
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                              ? 'Set one clear focus for next week.'
                              : null,
                        ),

                        const SizedBox(height: FinishXSpacing.xxl),

                        // Submit Reflection Mint Button
                        FinishXPrimaryButton(
                          label: 'Submit Reflection',
                          useMintFill: true,
                          isLoading: _isSubmitting,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: FinishXSpacing.lg),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoicePill({
    required String label,
    required WeeklyCompletionAnswer value,
  }) {
    final isSelected = _answer == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _answer = value),
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? FinishXColors.kineticMint
                : FinishXColors.cardSurface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: isSelected
                  ? FinishXColors.kineticMint
                  : FinishXColors.cardBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF091815)
                  : FinishXColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
