import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/pulso_theme_extension.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../comments/presentation/widgets/comments_sheet.dart';
import '../../../comments/presentation/providers/comment_notifier.dart';
import '../../domain/models/post.dart';
import 'like_button.dart';

/// Post card — design spec section 5.1.
///
/// surface-raised container, radius-md (20dp), neumorphic raised shadow.
/// 16:9 image with radius-sm (12dp) corners.
/// Entry animation: fade + slide up over 400ms, staggered by [index] × 60ms.
class PostCard extends StatefulWidget {
  const PostCard({super.key, required this.post, required this.index});

  final Post post;
  final int index;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    final delay = widget.index < 8 ? widget.index * 60 : 0;
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: NeumorphicContainer(
          state: NeumorphicState.raised,
          borderRadius: 20,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHeader(post: widget.post),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: widget.post.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const _ImageSkeleton(),
                    errorWidget: (_, _, _) => const _ImageError(),
                  ),
                ),
              ),
              if (widget.post.caption != null &&
                  widget.post.caption!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _Caption(
                  caption: widget.post.caption!,
                  expanded: _expanded,
                  onToggle: () => setState(() => _expanded = !_expanded),
                ),
              ],
              const SizedBox(height: 12),
              _ActionRow(post: widget.post),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        GestureDetector(
          onTap: () => context.push(AppRoutes.profileFor(post.userId)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Avatar(size: 40, avatarUrl: post.avatarUrl, username: post.username),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${post.username ?? 'user'}',
                    style: AppTextStyles.label.copyWith(color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _timeAgo(post.createdAt),
                    style: AppTextStyles.timestamp.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        Icon(Icons.more_horiz_rounded, color: cs.onSurfaceVariant, size: 20),
      ],
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

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.size, this.avatarUrl, this.username});

  final double size;
  final String? avatarUrl;
  final String? username;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pulso = context.pulso;

    final initials =
        username?.isNotEmpty == true ? username![0].toUpperCase() : '?';

    final fallback = _InitialsAvatar(
      initials: initials,
      primaryMuted: pulso.primaryMuted,
      amber: pulso.amber,
      primary: cs.primary,
      size: size,
    );

    final avatar = avatarUrl != null
        ? CachedNetworkImage(
            imageUrl: avatarUrl!,
            fit: BoxFit.cover,
            placeholder: (_, _) => fallback,
            errorWidget: (_, _, _) => fallback,
          )
        : fallback;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: cs.surface, width: 2),
      ),
      child: ClipOval(child: avatar),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({
    required this.initials,
    required this.primaryMuted,
    required this.amber,
    required this.primary,
    required this.size,
  });

  final String initials;
  final Color primaryMuted;
  final Color amber;
  final Color primary;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryMuted, amber],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.label.copyWith(
            color: primary,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}

// ─── Caption ──────────────────────────────────────────────────────────────────

class _Caption extends StatelessWidget {
  const _Caption({
    required this.caption,
    required this.expanded,
    required this.onToggle,
  });

  final String caption;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = AppTextStyles.body.copyWith(color: cs.onSurface);

    return LayoutBuilder(
      builder: (context, constraints) {
        final tp = TextPainter(
          text: TextSpan(text: caption, style: style),
          maxLines: 2,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              caption,
              style: style,
              maxLines: expanded ? null : 2,
              overflow: expanded ? null : TextOverflow.ellipsis,
            ),
            if (overflows)
              GestureDetector(
                onTap: onToggle,
                child: Text(
                  expanded ? 'less' : 'see more',
                  style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── Action Row ───────────────────────────────────────────────────────────────

class _ActionRow extends ConsumerStatefulWidget {
  const _ActionRow({required this.post});

  final Post post;

  @override
  ConsumerState<_ActionRow> createState() => _ActionRowState();

}

class _ActionRowState extends ConsumerState<_ActionRow> {
  bool _requestedCount = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedCount) return;
    _requestedCount = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(commentCountNotifierProvider.notifier).ensureLoaded(widget.post.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final commentCount = ref.watch(
      commentCountNotifierProvider
          .select((map) => map[widget.post.id] ?? 0),
    );

    return Row(
      children: [
        LikeButton(post: widget.post),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: () => _openComments(context),
          child: _IconStat(
            icon: Icons.chat_bubble_outline_rounded,
            count: commentCount,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 20),
        Icon(Icons.ios_share_rounded, size: 20, color: cs.onSurfaceVariant),
      ],
    );
  }

  Future<void> _openComments(BuildContext context) async {
    final theme = Theme.of(context);
    final sheetBg = theme.colorScheme.surface.withValues(alpha: 0);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      builder: (context) => CommentsSheet(post: widget.post),
    );
  }
}

class _IconStat extends StatelessWidget {
  const _IconStat({required this.icon, required this.count, required this.color});

  final IconData icon;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Text('$count', style: AppTextStyles.label.copyWith(color: color)),
      ],
    );
  }
}

// ─── Skeleton / Error states ──────────────────────────────────────────────────

class _ImageSkeleton extends StatefulWidget {
  const _ImageSkeleton();

  @override
  State<_ImageSkeleton> createState() => _ImageSkeletonState();
}

class _ImageSkeletonState extends State<_ImageSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pulso = context.pulso;
    final base = cs.surfaceContainerHighest;
    final shimmerColor = pulso.primaryMuted.withValues(alpha: 0.2);

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, _) => Container(
        decoration: BoxDecoration(
          color: base,
          gradient: LinearGradient(
            begin: Alignment(-1 + _shimmer.value * 3, 0),
            end: Alignment(0 + _shimmer.value * 3, 0),
            colors: [base, shimmerColor, base],
          ),
        ),
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pulso = context.pulso;
    return Container(
      color: pulso.surfaceInset,
      child: Center(
        child: Icon(Icons.broken_image_outlined, color: cs.onSurfaceVariant, size: 32),
      ),
    );
  }
}
