import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/medicine_inventory/medicine_providers.dart';
import '../features/notifications/notification_model.dart';
import '../features/notifications/notification_providers.dart';
import '../services/medicine_notification_helper.dart';
import '../theme/app_spacing.dart';
import '../utils/app_date_time_format.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/skeleton_placeholders.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  /// Ensures Firestore notification docs exist for low-stock / expiring medicines.
  /// Inventory list only syncs the first page of medicines; this loads all alerts.
  Future<void> _syncMedicineAlertsToFirestore(String uid) async {
    if (uid.isEmpty) return;
    try {
      final repo = ref.read(medicineRepositoryProvider);
      final all = await repo
          .watchAllMedicinesOrderedByName(userId: uid)
          .first
          .timeout(const Duration(seconds: 60));
      if (all.isEmpty) return;
      await MedicineNotificationHelper().checkAndCreateNotifications(all);
    } catch (e, st) {
      debugPrint('Medicine alert sync failed: $e\n$st');
    }
  }

  Future<void> _refresh(String uid) async {
    await _syncMedicineAlertsToFirestore(uid);
    ref.invalidate(userNotificationsStreamProvider(uid));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) return;
      _syncMedicineAlertsToFirestore(uid);
    });
  }

  Future<void> _markAsRead(String notificationId) async {
    await ref
        .read(notificationInboxProvider.notifier)
        .markAsRead(notificationId);
  }

  Future<void> _markAllAsRead() async {
    await ref.read(notificationInboxProvider.notifier).markAllAsRead();
  }

  Future<void> _deleteNotification(String notificationId) async {
    await ref
        .read(notificationInboxProvider.notifier)
        .deleteNotification(notificationId);
  }

  Future<void> _deleteAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all alerts?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(notificationInboxProvider.notifier)
          .deleteAllNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return Scaffold(
        appBar: AppScreenHeader(
          title: 'Alerts',
          subtitle: 'Medicine alerts and reminders',
          icon: Icons.notifications_rounded,
        ),
        body: const Center(child: Text('Sign in to view alerts.')),
      );
    }
    final notificationsAsync = ref.watch(userNotificationsStreamProvider(uid));
    final unreadCount = ref.watch(unreadNotificationsCountProvider(uid));

    ref.listen<NotificationInboxUiState>(notificationInboxProvider, (
      prev,
      next,
    ) {
      final msg = next.mutationError;
      if (msg != null && msg != prev?.mutationError) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
          ref.read(notificationInboxProvider.notifier).clearMutationError();
        });
      }
    });

    final hasItems = notificationsAsync.maybeWhen(
      data: (list) => list.isNotEmpty,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppScreenHeader(
        title: 'Alerts',
        subtitle: 'Medicine alerts and reminders (updates live)',
        icon: Icons.notifications_rounded,
        actions: [
          if (hasItems) ...[
            IconButton(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded),
              tooltip: 'Mark all as read',
            ),
            IconButton(
              onPressed: _deleteAllNotifications,
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Delete all',
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(uid),
        child: notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.45,
                    child: EmptyStateWidget(
                      icon: Icons.notifications_off_rounded,
                      title: 'No alerts yet',
                      subtitle:
                          'Medicine stock and expiry alerts will show up here.',
                      actionLabel: 'Refresh',
                      onAction: () => _refresh(uid),
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return NotificationCard(
                  notification: notification,
                  onMarkAsRead: () => _markAsRead(notification.id),
                  onDelete: () => _deleteNotification(notification.id),
                );
              },
            );
          },
          loading: () => const ListLoadingSkeleton(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              88,
            ),
          ),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                'Could not load notifications',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => _refresh(uid),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: hasItems
          ? Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      unreadCount == 0
                          ? 'All caught up!'
                          : '$unreadCount unread alert${unreadCount == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    this.onMarkAsRead,
    this.onDelete,
  });

  final AppNotification notification;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color getNotificationColor() {
      switch (notification.type) {
        case NotificationType.lowStock:
          return Colors.orange;
        case NotificationType.expiringSoon:
          return Colors.amber;
        case NotificationType.expired:
          return Colors.red;
      }
    }

    IconData getNotificationIcon() {
      switch (notification.type) {
        case NotificationType.lowStock:
          return Icons.warning_rounded;
        case NotificationType.expiringSoon:
          return Icons.schedule_rounded;
        case NotificationType.expired:
          return Icons.error_outline_rounded;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: notification.isRead ? null : onMarkAsRead,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: getNotificationColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  getNotificationIcon(),
                  color: getNotificationColor(),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: notification.isRead
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurface,
                                ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      notification.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: notification.isRead
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Text(
                          AppDateTimeFormat.formatShortRelativeWithTime(
                            notification.createdAt,
                          ),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: getNotificationColor().withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                          child: Text(
                            notification.type.displayName,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: getNotificationColor(),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        const Spacer(),
                        if (onDelete != null)
                          IconButton(
                            onPressed: onDelete,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            tooltip: 'Delete',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
