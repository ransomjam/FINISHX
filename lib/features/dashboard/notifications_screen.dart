import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers/app_providers.dart';
import '../../core/theme/finishx_colors.dart';
import '../../core/theme/finishx_spacing.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/widgets/finishx_card.dart';
import '../../core/widgets/finishx_empty_state.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsControllerProvider);
    final now = ref.watch(clockProvider)();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () => ref
                  .read(notificationsControllerProvider.notifier)
                  .markAllRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: FinishXSpacing.md),
          child: ResponsiveContainer(
            child: notifications.isEmpty
                ? const FinishXEmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: 'All caught up',
                    description:
                        'Session reminders, Sunday check-in invitations, and journey updates appear here.',
                  )
                : Column(
                    children: notifications.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FinishXCard(
                          variant: item.isRead
                              ? FinishXCardVariant.surface
                              : FinishXCardVariant.mintTint,
                          padding: const EdgeInsets.all(FinishXSpacing.md),
                          onTap: () {
                            ref
                                .read(notificationsControllerProvider.notifier)
                                .markAllRead();
                            if (item.actionRoute != null) {
                              context.go(item.actionRoute!);
                            }
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                item.isRead
                                    ? Icons.notifications_none_rounded
                                    : Icons.notifications_active_outlined,
                                size: 20,
                                color: FinishXColors.forestInk,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.body,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      DateTimeUtils.formatRelativeDateTime(
                                        item.createdAt,
                                        now,
                                      ),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ),
      ),
    );
  }
}
