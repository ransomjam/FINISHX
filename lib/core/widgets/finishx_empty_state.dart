import 'package:flutter/material.dart';
import '../theme/finishx_colors.dart';
import '../theme/finishx_spacing.dart';
import 'finishx_buttons.dart';
import 'finishx_card.dart';

/// Premium empty state card with calm typography and optional primary action.
class FinishXEmptyState extends StatelessWidget {
  const FinishXEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return FinishXCard(
      padding: const EdgeInsets.symmetric(
        horizontal: FinishXSpacing.xl,
        vertical: FinishXSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: FinishXColors.warmChalk,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: FinishXColors.softSage),
            ),
            child: Icon(icon, size: 26, color: FinishXColors.forestInk),
          ),
          const SizedBox(height: FinishXSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: FinishXSpacing.xs),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: FinishXColors.carbonSecondary,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: FinishXSpacing.lg),
            FinishXPrimaryButton(
              label: actionLabel!,
              onPressed: onAction,
              compact: true,
            ),
          ],
        ],
      ),
    );
  }
}
