import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this.client);

  final supabase.SupabaseClient client;

  @override
  Future<List<AppNotification>> fetchNotifications(String userId) async {
    try {
      final data = await client
          .from('notifications')
          .select('''
            *,
            actor:profiles!notifications_actor_id_fkey(username, avatar_url),
            post:posts!notifications_post_id_fkey(image_url)
          ''')
          .eq('recipient_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return (data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(AppNotification.fromMap)
          .toList();
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (_) {}
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('recipient_id', userId)
          .eq('is_read', false);
    } catch (_) {}
  }
}
