import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../auth/data/providers/auth_providers.dart';
import '../../data/providers/notification_providers.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

// ─── Notification State ───────────────────────────────────────────────────────

sealed class NotificationState {
  const NotificationState();
}

final class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

final class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

final class NotificationLoaded extends NotificationState {
  const NotificationLoaded(this.notifications);

  final List<AppNotification> notifications;

  int get unreadCount => notifications.where((n) => !n.isRead).length;
}

final class NotificationError extends NotificationState {
  const NotificationError(this.message);

  final String message;
}

// ─── Notification Notifier ────────────────────────────────────────────────────

final notificationNotifierProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);

class NotificationNotifier extends Notifier<NotificationState> {
  supabase.RealtimeChannel? _channel;

  @override
  NotificationState build() {
    ref.onDispose(_cancelSubscription);

    ref.listen(authStateChangesProvider, (previous, next) {
      final userId = next.asData?.value?.id;
      if (userId != null) {
        Future.microtask(() => _loadAndSubscribe(userId));
      } else {
        _cancelSubscription();
        state = const NotificationInitial();
      }
    });
    return const NotificationInitial();
  }

  NotificationRepository get _repository =>
      ref.read(notificationRepositoryProvider);

  String get _userId =>
      ref.read(supabaseClientProvider).auth.currentUser?.id ?? '';

  void _cancelSubscription() {
    final ch = _channel;
    if (ch != null) {
      ref.read(supabaseClientProvider).removeChannel(ch);
      _channel = null;
    }
  }

  Future<void> _loadAndSubscribe(String userId) async {
    await load();
    _cancelSubscription();
    _channel = ref
        .read(supabaseClientProvider)
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: supabase.PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: supabase.PostgresChangeFilter(
            type: supabase.PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: userId,
          ),
          callback: (_) => refresh(),
        )
        .subscribe();
  }

  Future<void> load() async {
    if (_userId.isEmpty) return;
    state = const NotificationLoading();
    try {
      final notifications = await _repository.fetchNotifications(_userId);
      state = NotificationLoaded(notifications);
    } catch (e) {
      state = NotificationError(e.toString());
    }
  }

  Future<void> refresh() async {
    if (_userId.isEmpty) return;
    try {
      final notifications = await _repository.fetchNotifications(_userId);
      state = NotificationLoaded(notifications);
    } catch (e) {
      state = NotificationError(e.toString());
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await _repository.markAsRead(notificationId);
    final current = state;
    if (current is NotificationLoaded) {
      final updated = current.notifications
          .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
          .toList();
      state = NotificationLoaded(updated);
    }
  }

  Future<void> markAllAsRead() async {
    if (_userId.isEmpty) return;
    await _repository.markAllAsRead(_userId);
    final current = state;
    if (current is NotificationLoaded) {
      final updated =
          current.notifications.map((n) => n.copyWith(isRead: true)).toList();
      state = NotificationLoaded(updated);
    }
  }
}

// ─── Unread count (derived from notifier state) ───────────────────────────────

final unreadNotificationCountProvider = Provider<int>((ref) {
  final s = ref.watch(notificationNotifierProvider);
  if (s is NotificationLoaded) return s.unreadCount;
  return 0;
});
