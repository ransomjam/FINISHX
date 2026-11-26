import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers/app_providers.dart';
import '../../core/theme/finishx_colors.dart';
import '../../core/theme/finishx_spacing.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/widgets/finishx_buttons.dart';
import '../../core/widgets/finishx_card.dart';
import '../../core/widgets/finishx_sync_banner.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  Future<void> _editName(String currentName) async {
    final ctrl = TextEditingController(text: currentName);
    final updated = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit display name'),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(96, 42)),
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (updated != null && updated.isNotEmpty) {
      await ref
          .read(authControllerProvider.notifier)
          .updateDisplayName(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final sync = ref.watch(syncControllerProvider);
    final queueCount = ref.watch(archiveQueueControllerProvider).queue.length;
    final user = auth.user;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: FinishXSpacing.xxl),
          child: ResponsiveContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user != null)
                  FinishXCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: FinishXColors.forestInk,
                          child: Text(
                            user.initials,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: FinishXColors.kineticMint,
                            ),
                          ),
                        ),
                        const SizedBox(width: FinishXSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name, style: textTheme.headlineSmall),
                              Text(user.email, style: textTheme.bodySmall),
                              const SizedBox(height: 4),
                              Text(
                                'Signed in via ${user.authProvider.label}${user.isDemoAccount ? ' (Local Demo)' : ''}',
                                style: textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit name',
                          onPressed: () => _editName(user.name),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: FinishXSpacing.lg),
                Text('PLANNING & REFLECTION', style: textTheme.labelSmall),
                const SizedBox(height: FinishXSpacing.xs),
                FinishXCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.layers_outlined,
                          color: FinishXColors.forestInk,
                        ),
                        title: const Text('Journey Queue'),
                        subtitle: Text(
                          queueCount == 0
                              ? 'Plan upcoming journeys while staying focused on one'
                              : '$queueCount planned ${queueCount == 1 ? 'journey' : 'journeys'} waiting',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/queue'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.auto_stories_outlined,
                          color: FinishXColors.forestInk,
                        ),
                        title: const Text('Weekly Check-In'),
                        subtitle: const Text(
                          'Complete or review Sunday weekly reflections',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/weekly-checkin'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: FinishXSpacing.lg),
                Text('OFFLINE & SYNCHRONISATION', style: textTheme.labelSmall),
                const SizedBox(height: FinishXSpacing.xs),
                FinishXCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FinishXSyncPill(status: sync),
                      const SizedBox(height: FinishXSpacing.sm),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        activeTrackColor: FinishXColors.forestInk,
                        activeThumbColor: FinishXColors.kineticMint,
                        title: const Text('Offline Mode'),
                        subtitle: const Text(
                          'Sessions, reflections, and updates continue working locally offline.',
                        ),
                        value: sync.isOfflineMode,
                        onChanged: (val) {
                          ref
                              .read(syncControllerProvider.notifier)
                              .toggleOfflineMode(val);
                        },
                      ),
                      const Divider(),
                      const SizedBox(height: 6),
                      Text(
                        'Pending local changes: ${sync.pendingOperationsCount}',
                        style: textTheme.bodySmall?.copyWith(
                          color: FinishXColors.carbon,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (sync.lastLocalSaveAt != null)
                        Text(
                          'Last saved on device: ${DateTimeUtils.formatMediumDate(sync.lastLocalSaveAt!)}',
                          style: textTheme.bodySmall,
                        ),
                      const SizedBox(height: 6),
                      Text(
                        sync.isRemoteBackendConfigured
                            ? 'Remote cloud sync active.'
                            : 'Remote backend not configured — changes remain safely persisted on device and queued for sync once connected.',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: FinishXSpacing.xl),
                FinishXSecondaryButton(
                  label: 'Sign Out',
                  isDestructive: true,
                  icon: Icons.logout_rounded,
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (context.mounted) {
                      context.go('/welcome');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
