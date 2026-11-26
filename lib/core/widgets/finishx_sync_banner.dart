import 'package:flutter/material.dart';
import '../../domain/enums/app_enums.dart';
import '../../domain/models/sync_status.dart';
import '../theme/finishx_colors.dart';
import '../theme/finishx_spacing.dart';
import '../theme/finishx_typography.dart';

/// Displays honest local persistence and synchronisation status.
///
/// Clearly distinguishes Synced, Pending synchronisation, and Offline states,
/// without ever faking remote backend synchronisation.
class FinishXSyncPill extends StatelessWidget {
  const FinishXSyncPill({super.key, required this.status, this.onTap});

  final SyncStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (label, icon, bgColor, fgColor) = switch (status.state) {
      SyncState.offline => (
        status.pendingOperationsCount > 0
            ? 'Offline · ${status.pendingOperationsCount} saved locally'
            : 'Offline mode · Saved on device',
        Icons.cloud_off_rounded,
        FinishXColors.softSage,
        FinishXColors.forestInk,
      ),
      SyncState.pendingSync => (
        status.isRemoteBackendConfigured
            ? 'Pending sync (${status.pendingOperationsCount})'
            : 'Saved locally · ${status.pendingOperationsCount} pending cloud sync',
        Icons.schedule_send_rounded,
        FinishXColors.mintSurface,
        FinishXColors.deepSpruce,
      ),
      SyncState.synced => (
        status.isRemoteBackendConfigured ? 'Synced' : 'Saved on device',
        Icons.check_circle_outline_rounded,
        FinishXColors.softSage.withValues(alpha: 0.7),
        FinishXColors.forestInk,
      ),
    };

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(FinishXSpacing.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FinishXSpacing.radiusPill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fgColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: FinishXTypography.bodyFont,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
