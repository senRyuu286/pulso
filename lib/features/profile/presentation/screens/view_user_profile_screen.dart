import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/data/providers/auth_providers.dart';
import '../../../feed/data/providers/feed_providers.dart';
import '../../../feed/domain/models/post.dart';
import '../../data/providers/profile_providers.dart';
import '../../domain/models/profile.dart';
import '../providers/follow_notifier.dart';
import '../widgets/profile_avatar.dart';

final _userPostsProvider = FutureProvider.family<List<Post>, String>(
  (ref, userId) => ref.watch(feedRepositoryProvider).fetchUserPosts(userId),
);

class ViewUserProfileScreen extends ConsumerStatefulWidget {
  const ViewUserProfileScreen({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  ConsumerState<ViewUserProfileScreen> createState() =>
      _ViewUserProfileScreenState();
}

class _ViewUserProfileScreenState
    extends ConsumerState<ViewUserProfileScreen> {
  int? _followerCountOverride;
  bool _requestedFollowLoad = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryD : AppColors.textPrimaryL;
    final textSecondary =
        isDark ? AppColors.textSecondaryD : AppColors.textSecondaryL;
    final primary = isDark ? AppColors.primaryD : AppColors.primaryL;
    final surfaceInset =
        isDark ? AppColors.surfaceInsetD : AppColors.surfaceInsetL;
    final surfaceRaised =
        isDark ? AppColors.surfaceRaisedD : AppColors.surfaceRaisedL;
    final shadowLight = isDark ? AppColors.shadowLightD : AppColors.shadowLightL;
    final shadowDark = isDark ? AppColors.shadowDarkD : AppColors.shadowDarkL;

    final profileAsync = ref.watch(fetchProfileProvider(widget.userId));
    final postsAsync = ref.watch(_userPostsProvider(widget.userId));
    final currentUserId =
        ref.read(supabaseClientProvider).auth.currentUser?.id;
    final followMap = ref.watch(followNotifierProvider);
    final followState = followMap[widget.userId] ?? const FollowChecking();

    if (!_requestedFollowLoad) {
      _requestedFollowLoad = true;
      Future.microtask(() {
        if (!mounted) {
          return;
        }
        ref.read(followNotifierProvider.notifier).load(widget.userId);
      });
    }

    ref.listen<AsyncValue<Profile>>(fetchProfileProvider(widget.userId),
        (previous, next) {
      if (next is AsyncData<Profile>) {
        final nextCount = next.value.followerCount;
        if (_followerCountOverride != nextCount) {
          if (!mounted) {
            return;
          }
          setState(() {
            _followerCountOverride = nextCount;
          });
        }
      }
    });

    ref.listen<FollowMap>(followNotifierProvider, (previous, next) {
      final prevState = previous?[widget.userId];
      final nextState = next[widget.userId];
      if (prevState is FollowLoaded && nextState is FollowLoaded) {
        if (prevState.isFollowing != nextState.isFollowing) {
          if (!mounted) {
            return;
          }
          setState(() {
            _followerCountOverride =
                (_followerCountOverride ?? 0) +
                (nextState.isFollowing ? 1 : -1);
          });
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: profileAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: primary),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Unable to load profile.',
                  style: AppTextStyles.body.copyWith(color: primary),
                ),
                TextButton(
                  onPressed: () =>
                      ref.refresh(fetchProfileProvider(widget.userId)),
                  child: Text(
                    'Retry',
                    style: AppTextStyles.label.copyWith(color: primary),
                  ),
                ),
              ],
            ),
          ),
          data: (profile) {
            final displayedProfile = profile.copyWith(
              followerCount:
                  _followerCountOverride ?? profile.followerCount,
            );
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => context.pop(),
                              icon: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 20,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              '@${profile.username}',
                              style:
                                  AppTextStyles.title.copyWith(color: textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: ProfileAvatar(
                            avatarUrl: profile.avatarUrl,
                            size: 120,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '@${profile.username}',
                          style: AppTextStyles.headline
                              .copyWith(color: textPrimary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        if (profile.bio != null)
                          Text(
                            profile.bio!,
                            style: AppTextStyles.body
                                .copyWith(color: textSecondary),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                          ),
                        const SizedBox(height: 24),
                        _StatsRow(
                          profile: displayedProfile,
                          surfaceInset: surfaceInset,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          shadowLight: shadowLight,
                          shadowDark: shadowDark,
                        ),
                        const SizedBox(height: 20),
                        if (currentUserId != widget.userId)
                          _FollowButton(
                            followState: followState,
                            surfaceRaised: surfaceRaised,
                            surfaceInset: surfaceInset,
                            shadowLight: shadowLight,
                            shadowDark: shadowDark,
                            textSecondary: textSecondary,
                            primary: primary,
                            onTap: followState is FollowLoaded
                                ? () => ref
                                    .read(followNotifierProvider.notifier)
                                    .toggle(widget.userId)
                                : null,
                          ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                _PostsSliver(
                  postsAsync: postsAsync,
                  textSecondary: textSecondary,
                  primary: primary,
                  isDark: isDark,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PostsSliver extends StatelessWidget {
  const _PostsSliver({
    required this.postsAsync,
    required this.textSecondary,
    required this.primary,
    required this.isDark,
  });

  final AsyncValue<List<Post>> postsAsync;
  final Color textSecondary;
  final Color primary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return postsAsync.when(
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: CircularProgressIndicator(color: primary),
          ),
        ),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Text(
            'Unable to load posts.',
            style: AppTextStyles.body.copyWith(color: primary),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Text(
                'No posts yet.',
                style: AppTextStyles.body.copyWith(color: textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _PostGridTile(
                post: posts[index],
                isDark: isDark,
              ),
              childCount: posts.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
          ),
        );
      },
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({
    required this.followState,
    required this.surfaceRaised,
    required this.surfaceInset,
    required this.shadowLight,
    required this.shadowDark,
    required this.textSecondary,
    required this.primary,
    required this.onTap,
  });

  final FollowState followState;
  final Color surfaceRaised;
  final Color surfaceInset;
  final Color shadowLight;
  final Color shadowDark;
  final Color textSecondary;
  final Color primary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final state = followState;
    final isFollowing =
      state is FollowLoaded ? state.isFollowing : false;
    final isLoading = followState is FollowChecking;
    final background = isFollowing ? surfaceInset : surfaceRaised;
    final labelColor = isFollowing ? textSecondary : primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: shadowLight,
              blurRadius: 14,
              offset: const Offset(-6, -6),
            ),
            BoxShadow(
              color: shadowDark,
              blurRadius: 14,
              offset: const Offset(6, 6),
            ),
          ],
        ),
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primary,
                ),
              )
            : Text(
                isFollowing ? 'Following' : 'Follow',
                style: AppTextStyles.title.copyWith(color: labelColor),
              ),
      ),
    );
  }
}

class _PostGridTile extends StatelessWidget {
  const _PostGridTile({
    required this.post,
    required this.isDark,
  });

  final Post post;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surfaceInset =
        isDark ? AppColors.surfaceInsetD : AppColors.surfaceInsetL;
    final textSecondary =
        isDark ? AppColors.textSecondaryD : AppColors.textSecondaryL;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.postDetailFor(post.id), extra: post),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: surfaceInset,
          child: Image.network(
            post.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Icon(Icons.broken_image_rounded, color: textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.profile,
    required this.surfaceInset,
    required this.textPrimary,
    required this.textSecondary,
    required this.shadowLight,
    required this.shadowDark,
  });

  final Profile profile;
  final Color surfaceInset;
  final Color textPrimary;
  final Color textSecondary;
  final Color shadowLight;
  final Color shadowDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Posts',
            value: profile.postCount,
            surfaceInset: surfaceInset,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            shadowLight: shadowLight,
            shadowDark: shadowDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Followers',
            value: profile.followerCount,
            surfaceInset: surfaceInset,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            shadowLight: shadowLight,
            shadowDark: shadowDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Following',
            value: profile.followingCount,
            surfaceInset: surfaceInset,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            shadowLight: shadowLight,
            shadowDark: shadowDark,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.surfaceInset,
    required this.textPrimary,
    required this.textSecondary,
    required this.shadowLight,
    required this.shadowDark,
  });

  final String label;
  final int value;
  final Color surfaceInset;
  final Color textPrimary;
  final Color textSecondary;
  final Color shadowLight;
  final Color shadowDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceInset,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadowDark,
            blurRadius: 10,
            offset: const Offset(6, 6),
          ),
          BoxShadow(
            color: shadowLight,
            blurRadius: 10,
            offset: const Offset(-6, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: AppTextStyles.title.copyWith(color: textPrimary),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: textSecondary),
          ),
        ],
      ),
    );
  }
}
