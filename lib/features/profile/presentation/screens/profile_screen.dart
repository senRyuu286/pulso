import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/data/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../feed/data/providers/feed_providers.dart';
import '../../../feed/domain/models/post.dart';
import '../../domain/models/profile.dart';
import '../providers/profile_notifier.dart';
import '../widgets/avatar_crop_preview.dart';

final _userPostsProvider = FutureProvider.family<List<Post>, String>(
  (ref, userId) => ref.watch(feedRepositoryProvider).fetchUserPosts(userId),
);

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _requestedLoad = false;
  String? _lastUserId;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);
    final profileState = ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    final textPrimary = isDark ? AppColors.textPrimaryD : AppColors.textPrimaryL;
    final textSecondary = isDark ? AppColors.textSecondaryD : AppColors.textSecondaryL;
    final primary = isDark ? AppColors.primaryD : AppColors.primaryL;

    final currentUserId = authState.asData?.value?.id;

    if (currentUserId != null && _lastUserId != currentUserId) {
      _lastUserId = currentUserId;
      _requestedLoad = false;
    }

    if (currentUserId != null && !_requestedLoad) {
      _requestedLoad = true;
      Future.microtask(() {
        if (!mounted) return;
        ref.read(profileProvider.notifier).loadProfile(currentUserId);
      });
    }

    Widget body;
    if (profileState is ProfileLoading || profileState is ProfileInitial) {
      body = Center(child: CircularProgressIndicator(color: primary));
    } else if (profileState is ProfileError) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              profileState.message,
              style: AppTextStyles.body.copyWith(color: primary),
            ),
            TextButton(
              onPressed: currentUserId == null
                  ? null
                  : () => ref.read(profileProvider.notifier).loadProfile(currentUserId),
              child: Text('Retry', style: AppTextStyles.label.copyWith(color: primary)),
            ),
          ],
        ),
      );
    } else if (profileState is ProfileLoaded || profileState is ProfileUpdating) {
      final profile = profileState is ProfileLoaded
          ? profileState.profile
          : (profileState as ProfileUpdating).profile;

      body = NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: _ProfileHeader(
              profile: profile,
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              primary: primary,
              onEditAvatar: currentUserId == null
                  ? null
                  : () => _pickAndUploadAvatar(context, currentUserId),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(tabController: _tabController, cs: cs),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _PostsTab(userId: profile.id),
            _RepostsTab(userId: profile.id),
          ],
        ),
      );
    } else {
      body = const SizedBox.shrink();
    }

    return Scaffold(
      body: SafeArea(child: body),
    );
  }

  Future<void> _pickAndUploadAvatar(BuildContext context, String userId) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (xFile == null) return;
    final bytes = await xFile.readAsBytes();
    if (!context.mounted) return;
    final theme = Theme.of(context);
    final sheetBg = (theme.brightness == Brightness.dark
            ? AppColors.surfaceD
            : AppColors.surfaceL)
        .withValues(alpha: 0);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      builder: (context) {
        return AvatarCropPreview(
          imageBytes: bytes,
          onConfirm: () {
            Navigator.of(context).pop();
            final extension = xFile.name.split('.').last;
            ref.read(profileProvider.notifier).uploadAvatar(
                  userId: userId,
                  imageBytes: bytes,
                  fileExtension: extension,
                );
          },
          onCancel: () => Navigator.of(context).pop(),
        );
      },
    );
  }
}

// ─── Tab Bar Delegate ─────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate({required this.tabController, required this.cs});

  final TabController tabController;
  final ColorScheme cs;

  static const double _height = 46;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) =>
      oldDelegate.tabController != tabController;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: cs.surface,
      child: TabBar(
        controller: tabController,
        labelColor: cs.onSurface,
        unselectedLabelColor: cs.onSurfaceVariant,
        indicatorColor: cs.onSurface,
        indicatorWeight: 1.5,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: cs.outline.withValues(alpha: 0.3),
        tabs: const [
          Tab(icon: Icon(Icons.grid_on_rounded, size: 22)),
          Tab(icon: Icon(Icons.repeat_rounded, size: 22)),
        ],
      ),
    );
  }
}

// ─── Profile Header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
    required this.onEditAvatar,
  });

  final Profile profile;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;
  final VoidCallback? onEditAvatar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Circular avatar + black "+" badge ────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: onEditAvatar,
                    child: _CircularAvatar(
                      size: 90,
                      avatarUrl: profile.avatarUrl,
                      username: profile.username,
                    ),
                  ),
                  if (onEditAvatar != null)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: onEditAvatar,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.surfaceD : AppColors.surfaceL,
                              width: 2,
                            ),
                          ),
                          child: const Icon(Icons.add, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              // ── Info column: display name + username + stats ─────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName?.isNotEmpty == true
                          ? profile.displayName!
                          : profile.username.isNotEmpty
                              ? profile.username
                              : 'user',
                      style: AppTextStyles.title.copyWith(color: textPrimary),
                    ),
                    Text(
                      profile.username.isNotEmpty ? profile.username : 'user',
                      style: AppTextStyles.body.copyWith(color: textSecondary),
                    ),
                    const SizedBox(height: 8),
                    _StatsRow(
                      profile: profile,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ActionButtonRow(profile: profile),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Circular Avatar ─────────────────────────────────────────────────────────

class _CircularAvatar extends StatelessWidget {
  const _CircularAvatar({
    required this.size,
    this.avatarUrl,
    this.username,
  });

  final double size;
  final String? avatarUrl;
  final String? username;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceInsetD : AppColors.surfaceInsetL;
    final fg = isDark ? AppColors.textSecondaryD : AppColors.textSecondaryL;
    final initial = username?.isNotEmpty == true ? username![0].toUpperCase() : null;

    final Widget fallback = Container(
      width: size,
      height: size,
      color: bg,
      child: Center(
        child: initial != null
            ? Text(
                initial,
                style: AppTextStyles.label.copyWith(
                  color: fg,
                  fontSize: size * 0.38,
                  height: 1,
                ),
              )
            : Icon(Icons.person_rounded, size: size * 0.55, color: fg),
      ),
    );

    final Widget content = (avatarUrl != null && avatarUrl!.isNotEmpty)
        ? CachedNetworkImage(
            imageUrl: avatarUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (_, _) => fallback,
            errorWidget: (_, _, _) => fallback,
          )
        : fallback;

    return ClipOval(
      child: SizedBox(width: size, height: size, child: content),
    );
  }
}

// ─── Action Button Row ────────────────────────────────────────────────────────

class _ActionButtonRow extends ConsumerWidget {
  const _ActionButtonRow({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Edit profile',
            onPressed: () => context.push(AppRoutes.editProfile, extra: profile),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            label: 'Sign out',
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(color: cs.onSurface, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// ─── Posts Tab ────────────────────────────────────────────────────────────────

class _PostsTab extends ConsumerWidget {
  const _PostsTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final postsAsync = ref.watch(_userPostsProvider(userId));

    return postsAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: cs.primary)),
      error: (_, _) => Center(
        child: Text(
          'Unable to load posts.',
          style: AppTextStyles.body.copyWith(color: cs.onSurfaceVariant),
        ),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Text(
              'No posts yet.',
              style: AppTextStyles.body.copyWith(color: cs.onSurfaceVariant),
            ),
          );
        }
        return GridView.builder(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
          ),
          itemCount: posts.length,
          itemBuilder: (_, index) => _PostGridTile(post: posts[index]),
        );
      },
    );
  }
}

// ─── Reposts Tab ──────────────────────────────────────────────────────────────

class _RepostsTab extends ConsumerWidget {
  const _RepostsTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final repostsAsync = ref.watch(repostsByUserProvider(userId));

    return repostsAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: cs.primary)),
      error: (_, _) => Center(
        child: Text(
          'Unable to load reposts.',
          style: AppTextStyles.body.copyWith(color: cs.onSurfaceVariant),
        ),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.repeat_rounded, size: 48, color: cs.onSurfaceVariant),
                const SizedBox(height: 12),
                Text(
                  'No reposts yet.',
                  style: AppTextStyles.body.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          );
        }
        return GridView.builder(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
          ),
          itemCount: posts.length,
          itemBuilder: (_, index) => _PostGridTile(post: posts[index]),
        );
      },
    );
  }
}

// ─── Post Grid Tile ───────────────────────────────────────────────────────────

class _PostGridTile extends StatelessWidget {
  const _PostGridTile({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push(AppRoutes.postDetailFor(post.id), extra: post),
      child: CachedNetworkImage(
        imageUrl: post.imageUrl,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(color: cs.surfaceContainerHighest),
        errorWidget: (_, _, _) => Container(
          color: cs.surfaceContainerHighest,
          child: Icon(Icons.broken_image_rounded, color: cs.onSurfaceVariant),
        ),
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.profile,
    required this.textPrimary,
    required this.textSecondary,
  });

  final Profile profile;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: profile.postCount == 1 ? 'post' : 'posts',
            value: profile.postCount,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'followers',
            value: profile.followerCount,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'following',
            value: profile.followingCount,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
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
    required this.textPrimary,
    required this.textSecondary,
  });

  final String label;
  final int value;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}
