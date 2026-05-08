import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/neumorphic_container.dart';
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

  // Caption expand/collapse
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
      begin: const Offset(0, 0.06), // ~12dp at 200dp height
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    // Stagger first 8 cards by 60ms each; beyond that — no delay
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryD : AppColors.textPrimaryL;
    final textSecondary = isDark ? AppColors.textSecondaryD : AppColors.textSecondaryL;

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: NeumorphicContainer(
          state: NeumorphicState.raised,
          borderRadius: 20, // radius-md
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──────────────────────────────────────────────
              _CardHeader(post: widget.post, textPrimary: textPrimary, textSecondary: textSecondary),
              const SizedBox(height: 12),

              // ── Post image (16:9, radius-sm) ─────────────────────────────
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12), // radius-sm
                  child: CachedNetworkImage(
                    imageUrl: widget.post.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => _ImageSkeleton(isDark: isDark),
                    errorWidget: (_, _, _) => _ImageError(isDark: isDark),
                  ),
                ),
              ),

              // ── Caption ─────────────────────────────────────────────────
              if (widget.post.caption != null && widget.post.caption!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _Caption(
                  caption: widget.post.caption!,
                  expanded: _expanded,
                  onToggle: () => setState(() => _expanded = !_expanded),
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ],

              // ── Action row ───────────────────────────────────────────────
              const SizedBox(height: 12),
              _ActionRow(post: widget.post, textSecondary: textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.post,
    required this.textPrimary,
    required this.textSecondary,
  });

  final Post post;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Avatar(
          size: 40,
          avatarUrl: post.avatarUrl,
          username: post.username,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.username ?? 'User',
                style: AppTextStyles.label.copyWith(color: textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _timeAgo(post.createdAt),
                style: AppTextStyles.timestamp.copyWith(color: textSecondary),
              ),
            ],
          ),
        ),
        Icon(Icons.more_horiz_rounded, color: textSecondary, size: 20),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryMuted = isDark ? AppColors.primaryMutedD : AppColors.primaryMutedL;
    final amber = isDark ? AppColors.amberD : AppColors.amberL;
    final primary = isDark ? AppColors.primaryD : AppColors.primaryL;
    final surface = isDark ? AppColors.surfaceD : AppColors.surfaceL;

    final initials = username?.isNotEmpty == true
        ? username![0].toUpperCase()
        : '?';

    final avatar = avatarUrl != null
        ? CachedNetworkImage(
            imageUrl: avatarUrl!,
            fit: BoxFit.cover,
            placeholder: (_, _) => _InitialsAvatar(
              initials: initials,
              primaryMuted: primaryMuted,
              amber: amber,
              primary: primary,
              size: size,
            ),
            errorWidget: (_, _, _) => _InitialsAvatar(
              initials: initials,
              primaryMuted: primaryMuted,
              amber: amber,
              primary: primary,
              size: size,
            ),
          )
        : _InitialsAvatar(
            initials: initials,
            primaryMuted: primaryMuted,
            amber: amber,
            primary: primary,
            size: size,
          );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // 2dp border in surface color to lift off background
        border: Border.all(color: surface, width: 2),
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
    required this.textPrimary,
    required this.textSecondary,
  });

  final String caption;
  final bool expanded;
  final VoidCallback onToggle;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.body.copyWith(color: textPrimary);

    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(text: caption, style: style);
        final tp = TextPainter(
          text: span,
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
                  style: AppTextStyles.caption.copyWith(color: textSecondary),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── Action Row ───────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.post, required this.textSecondary});

  final Post post;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Like — full heartbeat animation
        LikeButton(post: post),
        const SizedBox(width: 20),
        // Comment (non-interactive placeholder for now)
        _IconStat(
          icon: Icons.chat_bubble_outline_rounded,
          count: 0,
          color: textSecondary,
        ),
        const SizedBox(width: 20),
        // Share
        Icon(Icons.ios_share_rounded, size: 20, color: textSecondary),
      ],
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
        Text(
          '$count',
          style: AppTextStyles.label.copyWith(color: color),
        ),
      ],
    );
  }
}

// ─── Skeleton / Error states ──────────────────────────────────────────────────

class _ImageSkeleton extends StatefulWidget {
  const _ImageSkeleton({required this.isDark});

  final bool isDark;

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
    final base = widget.isDark ? AppColors.surfaceRaisedD : AppColors.surfaceRaisedL;
    final shimmerColor = widget.isDark
        ? AppColors.primaryMutedD.withValues(alpha: 0.2)
        : AppColors.primaryMutedL.withValues(alpha: 0.2);

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
  const _ImageError({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.textSecondaryD : AppColors.textSecondaryL;
    return Container(
      color: isDark ? AppColors.surfaceInsetD : AppColors.surfaceInsetL,
      child: Center(child: Icon(Icons.broken_image_outlined, color: color, size: 32)),
    );
  }
}
