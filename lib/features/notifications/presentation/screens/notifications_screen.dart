import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/app_notification.dart';
import '../providers/notification_notifier.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _requestedLoad = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final notifState = ref.watch(notificationNotifierProvider);

    if (!_requestedLoad) {
      _requestedLoad = true;
      Future.microtask(
          () => ref.read(notificationNotifierProvider.notifier).load());
    }

    return Scaffold(
      body: SafeArea(
        child: switch (notifState) {
          NotificationInitial() || NotificationLoading() => Center(
              child: CircularProgressIndicator(color: cs.primary),
            ),
          NotificationError() => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Unable to load notifications.',
                      style: AppTextStyles.body
                          .copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => ref
                        .read(notificationNotifierProvider.notifier)
                        .load(),
                    child: Text('Retry',
                        style: AppTextStyles.label.copyWith(color: cs.primary)),
                  ),
                ],
              ),
            ),
          NotificationLoaded(:final notifications) when notifications.isEmpty =>
            Center(
              child: Text(
                'No notifications yet.',
                style: AppTextStyles.body.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          NotificationLoaded(:final notifications) => RefreshIndicator(
              onRefresh: () =>
                  ref.read(notificationNotifierProvider.notifier).refresh(),
              child: Column(
                children: [
                  if (notifications.any((n) => !n.isRead))
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => ref
                                .read(notificationNotifierProvider.notifier)
                                .markAllAsRead(),
                            child: Text(
                              'Mark all read',
                              style: AppTextStyles.caption
                                  .copyWith(color: cs.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) => _NotificationTile(
                        notification: notifications[index],
                        onTap: () {
                          ref
                              .read(notificationNotifierProvider.notifier)
                              .markAsRead(notifications[index].id);
                          context.push(
                            AppRoutes.postDetailFor(notifications[index].postId),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread
            ? cs.primaryContainer.withValues(alpha: 0.15)
            : Colors.transparent,
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            _ActorAvatar(
              avatarUrl: notification.actorAvatarUrl,
              username: notification.actorUsername ?? '',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.body.copyWith(color: cs.onSurface),
                      children: [
                        TextSpan(
                          text: '@${notification.actorUsername ?? 'someone'}',
                          style: AppTextStyles.label
                              .copyWith(color: cs.onSurface),
                        ),
                        const TextSpan(text: ' shared a new post.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(notification.createdAt),
                    style: AppTextStyles.timestamp
                        .copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (notification.postImageUrl != null) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: notification.postImageUrl!,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => Container(
                    width: 44,
                    height: 44,
                    color: cs.surfaceContainerHighest,
                  ),
                ),
              ),
            ],
            if (isUnread)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

class _ActorAvatar extends StatelessWidget {
  const _ActorAvatar({required this.avatarUrl, required this.username});

  final String? avatarUrl;
  final String username;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = username.isNotEmpty ? username[0].toUpperCase() : '?';

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: cs.surfaceContainerHighest,
        backgroundImage: CachedNetworkImageProvider(avatarUrl!),
        onBackgroundImageError: (_, _) {},
      );
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: cs.primaryContainer,
      child: Text(
        initials,
        style: AppTextStyles.label.copyWith(color: cs.onPrimaryContainer),
      ),
    );
  }
}
