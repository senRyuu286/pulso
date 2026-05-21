import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/comment.dart';

/// Comment card widget — displays a single comment.
class CommentCard extends StatelessWidget {
  const CommentCard({
    super.key,
    required this.comment,
    this.onLikeTap,
    this.onDeleteTap,
  });

  final Comment comment;
  final VoidCallback? onLikeTap;
  final VoidCallback? onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          GestureDetector(
            onTap: () => context.push(AppRoutes.profileFor(comment.userId)),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cs.surface, width: 1.5),
              ),
              child: comment.avatarUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: comment.avatarUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        (comment.username?.isNotEmpty == true
                                ? comment.username![0]
                                : '?')
                            .toUpperCase(),
                        style: AppTextStyles.label
                            .copyWith(fontSize: 12, color: cs.primary),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '@${comment.username ?? 'user'}',
                      style: AppTextStyles.label.copyWith(color: cs.onSurface),
                    ),
                    Text(
                      _timeAgo(comment.createdAt),
                      style: AppTextStyles.timestamp
                          .copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: AppTextStyles.body.copyWith(color: cs.onSurface),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Like and delete actions
                Row(
                  children: [
                    GestureDetector(
                      onTap: onLikeTap,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            comment.isLikedByMe
                                ? Icons.favorite
                                : Icons.favorite_border_rounded,
                            size: 16,
                            color: comment.isLikedByMe
                                ? cs.primary
                                : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${comment.likesCount}',
                            style: AppTextStyles.caption.copyWith(
                              color: comment.isLikedByMe
                                  ? cs.primary
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (onDeleteTap != null)
                      GestureDetector(
                        onTap: onDeleteTap,
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: cs.error,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
