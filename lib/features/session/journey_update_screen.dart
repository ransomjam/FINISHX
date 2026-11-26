import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers/app_providers.dart';
import '../../core/theme/finishx_colors.dart';
import '../../core/theme/finishx_spacing.dart';
import '../../core/widgets/finishx_buttons.dart';
import '../../core/widgets/finishx_card.dart';
import '../../data/datasources/demo_seed_datasource.dart';

class JourneyUpdateScreen extends ConsumerStatefulWidget {
  const JourneyUpdateScreen({super.key, this.sessionId});

  final String? sessionId;

  @override
  ConsumerState<JourneyUpdateScreen> createState() =>
      _JourneyUpdateScreenState();
}

class _JourneyUpdateScreenState extends ConsumerState<JourneyUpdateScreen> {
  final _textController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _saveUpdate() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      context.go('/home');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref
          .read(journeyWorkspaceProvider.notifier)
          .addJourneyUpdate(text: text, sessionId: widget.sessionId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Journey update recorded.')));
      context.go('/home');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journey Update'),
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: FinishXSpacing.xxl),
          child: ResponsiveContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What progress did you make today?',
                  style: textTheme.displaySmall,
                ),
                const SizedBox(height: FinishXSpacing.xs),
                Text(
                  'Optional — capture a short milestone for your journey log and group feed.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: FinishXColors.carbonSecondary,
                  ),
                ),
                const SizedBox(height: FinishXSpacing.lg),
                TextField(
                  controller: _textController,
                  maxLines: 3,
                  maxLength: 180,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Completed Module 4',
                  ),
                ),
                const SizedBox(height: FinishXSpacing.sm),
                Text('EXAMPLES', style: textTheme.labelSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: DemoSeedDataSource.updateInspirationExamples
                      .map(
                        (example) => ActionChip(
                          label: Text(example),
                          onPressed: () {
                            _textController.text = example;
                            _textController.selection = TextSelection.collapsed(
                              offset: example.length,
                            );
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: FinishXSpacing.xl),
                FinishXPrimaryButton(
                  label: 'Save Update',
                  isLoading: _isSaving,
                  onPressed: _saveUpdate,
                ),
                const SizedBox(height: 10),
                FinishXSecondaryButton(
                  label: 'Skip for Now',
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
