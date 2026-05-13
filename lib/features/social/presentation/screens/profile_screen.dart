import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/pulso_theme_extension.dart';
import '../../../auth/data/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../feed/domain/models/post.dart';
import '../../domain/models/user_profile.dart';
import '../providers/follow_notifier.dart';
import '../providers/profile_notifier.dart';
import '../widgets/follow_button.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileNotifierProvider.notifier).load(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        ref.read(supabaseClientProvider).auth.currentUser?.id ?? '';
    final isOwnProfile = currentUserId == widget.userId;
    final profileState =
        ref.watch(profileNotifierProvider)[widget.userId] ??
            const ProfileLoading();

    // Sync follower count when the follow button is toggled on this profile.
    ref.listen<FollowMap>(followNotifierProvider, (prev, next) {
      final prevState = prev?[widget.userId];
      final nextState = next[widget.userId];
      if (prevState is FollowLoaded && nextState is FollowLoaded) {
        if (prevState.isFollowing != nextState.isFollowing) {
          ref.read(profileNotifierProvider.notifier).adjustFollowerCount(
                widget.userId,
                nextState.isFollowing ? 1 : -1,
              );
        }
      }
    });

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const BackButton(),
        title: profileState is ProfileLoaded
            ? Text(
                profileState.profile.username,
                style: AppTextStyles.label.copyWith(color: cs.onSurface),
              )
            : null,
        actions: isOwnProfile
            ? [
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  tooltip: 'Sign out',
                  onPressed: () =>
                      ref.read(authNotifierProvider.notifier).signOut(),
                ),
              ]
            : null,
      ),
      body: switch (profileState) {
        ProfileLoading() => const Center(child: CircularProgressIndicator()),
        ProfileError(:final message) => _ErrorView(
            message: message,
            onRetry: () => ref
                .read(profileNotifierProvider.notifier)
                .refresh(widget.userId),
          ),
        ProfileLoaded(:final profile, :final posts) => RefreshIndicator(
            onRefresh: () => ref
                .read(profileNotifierProvider.notifier)
                .refresh(widget.userId),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _ProfileHeader(
                    profile: profile,
                    isOwnProfile: isOwnProfile,
                    userId: widget.userId,
                  ),
                ),
                if (posts.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyPostsView(),
                  )
                else
                  SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _PostThumb(post: posts[i]),
                      childCount: posts.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                  ),
              ],
            ),
          ),
      },
    );
  }
}

// ─── Profile Header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.isOwnProfile,
    required this.userId,
  });

  final UserProfile profile;
  final bool isOwnProfile;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(
                size: 80,
                avatarUrl: profile.avatarUrl,
                username: profile.username,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat(label: 'Posts', count: profile.postsCount),
                    _Stat(label: 'Followers', count: profile.followersCount),
                    _Stat(label: 'Following', count: profile.followingCount),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            profile.username,
            style: AppTextStyles.label.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: 16),
          if (!isOwnProfile)
            FollowButton(targetUserId: userId)
          else
            _EditProfileButton(),
          const SizedBox(height: 16),
          Divider(color: cs.outlineVariant, height: 1),
        ],
      ),
    );
  }
}

class _EditProfileButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pulso = context.pulso;

    return Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: pulso.shadowLight,
            offset: const Offset(-4, -4),
            blurRadius: pulso.shadowBlur,
          ),
          BoxShadow(
            color: pulso.shadowDark,
            offset: const Offset(4, 4),
            blurRadius: pulso.shadowBlur,
          ),
        ],
      ),
      child: Center(
        child: Text(
          'Edit Profile',
          style: AppTextStyles.label.copyWith(color: cs.onSurfaceVariant),
        ),
      ),
    );
  }
}

// ─── Stat Column ──────────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _fmt(count),
          style: AppTextStyles.title.copyWith(color: cs.onSurface),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
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

    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [pulso.primaryMuted, pulso.amber],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.title.copyWith(
            color: cs.primary,
            fontSize: size * 0.35,
          ),
        ),
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: cs.surface, width: 3),
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? CachedNetworkImage(
                imageUrl: avatarUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) => fallback,
                errorWidget: (_, _, _) => fallback,
              )
            : fallback,
      ),
    );
  }
}

// ─── Post Thumbnail ───────────────────────────────────────────────────────────

class _PostThumb extends StatelessWidget {
  const _PostThumb({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pulso = context.pulso;

    return CachedNetworkImage(
      imageUrl: post.imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, _) =>
          Container(color: cs.surfaceContainerHighest),
      errorWidget: (_, _, _) => Container(
        color: pulso.surfaceInset,
        child: Icon(
          Icons.broken_image_outlined,
          color: cs.onSurfaceVariant,
          size: 20,
        ),
      ),
    );
  }
}

// ─── Empty / Error States ─────────────────────────────────────────────────────

class _EmptyPostsView extends StatelessWidget {
  const _EmptyPostsView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 48,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No posts yet.',
            style: AppTextStyles.body.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.body.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Try again',
                style: AppTextStyles.label.copyWith(color: cs.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
