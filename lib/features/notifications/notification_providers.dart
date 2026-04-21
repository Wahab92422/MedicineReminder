import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_model.dart';
import 'notification_repository.dart';

const _sentinel = Object();

final _firestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(firestore: ref.watch(_firestoreProvider)),
);

/// Real-time list (Firestore snapshots). Prefer this over one-shot [getNotifications].
final userNotificationsStreamProvider =
    StreamProvider.autoDispose.family<List<AppNotification>, String>((
  ref,
  userId,
) {
  if (userId.isEmpty) {
    return Stream.value(const <AppNotification>[]);
  }
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.watchNotifications(userId: userId);
});

/// Unread count derived from the live stream (keeps badges / footer in sync).
final unreadNotificationsCountProvider = Provider.autoDispose.family<int, String>(
  (ref, userId) {
    final async = ref.watch(userNotificationsStreamProvider(userId));
    return async.when(
      data: (list) => list.where((n) => !n.isRead).length,
      loading: () => 0,
      error: (_, _) => 0,
    );
  },
);

/// One-shot fetch (e.g. rare callers); prefer [userNotificationsStreamProvider] in UI.
@Deprecated('Use userNotificationsStreamProvider for realtime updates')
final notificationsProvider =
    FutureProvider.family<List<AppNotification>, String>((ref, userId) async {
      final repo = ref.watch(notificationRepositoryProvider);
      return repo.getNotifications(userId: userId);
    });

@immutable
class NotificationInboxUiState {
  const NotificationInboxUiState({this.mutationError});

  final String? mutationError;

  static const initial = NotificationInboxUiState();

  NotificationInboxUiState copyWith({
    Object? mutationError = _sentinel,
    bool clearMutationError = false,
  }) {
    return NotificationInboxUiState(
      mutationError: clearMutationError
          ? null
          : (mutationError == _sentinel
                ? this.mutationError
                : mutationError as String?),
    );
  }
}

/// Mutations only; list data comes from [userNotificationsStreamProvider].
class NotificationInboxNotifier extends Notifier<NotificationInboxUiState> {
  @override
  NotificationInboxUiState build() => NotificationInboxUiState.initial;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> markAsRead(String notificationId) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.markAsRead(userId: uid, notificationId: notificationId);
      state = state.copyWith(clearMutationError: true);
    } catch (e) {
      state = state.copyWith(mutationError: 'Failed to mark notification as read');
    }
  }

  Future<void> markAllAsRead() async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.markAllAsRead(userId: uid);
      state = state.copyWith(clearMutationError: true);
    } catch (e) {
      state = state.copyWith(mutationError: 'Failed to mark all notifications as read');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.deleteNotification(
        userId: uid,
        notificationId: notificationId,
      );
      state = state.copyWith(clearMutationError: true);
    } catch (e) {
      state = state.copyWith(mutationError: 'Failed to delete notification');
    }
  }

  Future<void> deleteAllNotifications() async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.deleteAllNotifications(userId: uid);
      state = state.copyWith(clearMutationError: true);
    } catch (e) {
      state = state.copyWith(mutationError: 'Failed to delete all notifications');
    }
  }

  void clearMutationError() {
    state = state.copyWith(clearMutationError: true);
  }
}

final notificationInboxProvider =
    NotifierProvider<NotificationInboxNotifier, NotificationInboxUiState>(
      NotificationInboxNotifier.new,
    );
