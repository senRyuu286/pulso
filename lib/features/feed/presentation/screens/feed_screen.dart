import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../providers/feed_notifier.dart';
import '../widgets/post_card.dart';

/// Main feed screen — design spec section 9.
///
/// Sticky wordmark top bar, single-column post list with pull-to-refresh,
/// neumorphic bottom navigation bar with Home / Search / Create / Notifications / Profile.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedNotifierProvider.notifier).loadFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceD : AppColors.surfaceL;

    return Scaffold(
      backgroundColor: surface,
      extendBody: true,
      appBar: _PulsoAppBar(isDark: isDark),
      body: const _FeedBody(),
      bottomNavigationBar: _NeumorphicNav(
        selectedIndex: _selectedTab,
        onTap: (i) {
          if (i == 2) {
            // Create tab → push creation screen
            context.push(AppRoutes.createPost);
            return;
          }
          setState(() => _selectedTab = i);
        },
        isDark: isDark,
      ),
    );
  }
}

// ─── Top App Bar ─────────────────────────────────────────────────────────────

class _PulsoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _PulsoAppBar({required this.isDark});

  final bool isDark;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimaryD : AppColors.textPrimaryL;
    final textSecondary = isDark ? AppColors.textSecondaryD : AppColors.textSecondaryL;
    final surface = isDark ? AppColors.surfaceD : AppColors.surfaceL;

    return Container(
      color: surface,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 20,
        right: 20,
      ),
      height: preferredSize.height + MediaQuery.of(context).padding.top,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Pulso wordmark — Fraunces italic, display weight
          Text(
            'Pulso',
            style: GoogleFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: textPrimary,
              height: 1.0,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.notifications_none_rounded,
            size: 24,
            color: textSecondary,
          ),
        ],
      ),
    );
  }
}

// ─── Feed Body ────────────────────────────────────────────────────────────────

class _FeedBody extends ConsumerWidget {
  const _FeedBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return switch (feedState) {
      FeedInitial() => const _LoadingView(),
      FeedLoading()  => const _LoadingView(),
      FeedError(:final exception) => _ErrorView(
          message: exception.message,
          onRetry: () => ref.read(feedNotifierProvider.notifier).loadFeed(),
          isDark: isDark,
        ),
      FeedLoaded(:final posts) when posts.isEmpty => _EmptyView(isDark: isDark),
      FeedLoaded(:final posts) => RefreshIndicator(
          color: isDark ? AppColors.primaryD : AppColors.primaryL,
          backgroundColor: isDark ? AppColors.surfaceRaisedD : AppColors.surfaceRaisedL,
          onRefresh: () => ref.read(feedNotifierProvider.notifier).refresh(),
          child: ListView.builder(
            padding: EdgeInsets.only(
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 80, // nav bar height
            ),
            itemCount: posts.length,
            itemBuilder: (context, i) => PostCard(post: posts[i], index: i),
          ),
        ),
    };
  }
}

// ─── Loading / Empty / Error States ──────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: 4,
      itemBuilder: (_, i) => _SkeletonCard(isDark: isDark),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard({required this.isDark});

  final bool isDark;

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.isDark ? AppColors.surfaceRaisedD : AppColors.surfaceRaisedL;
    final shimmer = widget.isDark
        ? AppColors.primaryMutedD.withValues(alpha: 0.2)
        : AppColors.primaryMutedL.withValues(alpha: 0.2);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final gradient = LinearGradient(
          begin: Alignment(-1 + _ctrl.value * 3, 0),
          end: Alignment(0 + _ctrl.value * 3, 0),
          colors: [base, shimmer, base],
        );

        Widget block(double w, double h, {double r = 8}) => Container(
              width: w,
              height: h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(r),
                gradient: gradient,
              ),
            );

        return NeumorphicContainer(
          state: NeumorphicState.raised,
          borderRadius: 20,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  block(40, 40, r: 999),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      block(120, 12),
                      const SizedBox(height: 6),
                      block(80, 10),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AspectRatio(aspectRatio: 16 / 9, child: block(double.infinity, 0, r: 12)),
              const SizedBox(height: 12),
              block(double.infinity, 12),
              const SizedBox(height: 6),
              block(200, 12),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyView extends StatefulWidget {
  const _EmptyView({required this.isDark});

  final bool isDark;

  @override
  State<_EmptyView> createState() => _EmptyViewState();
}

class _EmptyViewState extends State<_EmptyView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathe;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryMuted = widget.isDark ? AppColors.primaryMutedD : AppColors.primaryMutedL;
    final textSecondary = widget.isDark ? AppColors.textSecondaryD : AppColors.textSecondaryL;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _breathe,
            builder: (_, _) => Transform.scale(
              scale: 0.95 + _breathe.value * 0.1,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [primaryMuted, primaryMuted.withValues(alpha: 0)],
                  ),
                ),
                child: Icon(
                  Icons.photo_library_outlined,
                  size: 36,
                  color: primaryMuted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No posts yet.',
            style: AppTextStyles.title.copyWith(color: textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share a moment.',
            style: AppTextStyles.body.copyWith(color: textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.isDark,
  });

  final String message;
  final VoidCallback onRetry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.textSecondaryD : AppColors.textSecondaryL;
    final primary = isDark ? AppColors.primaryD : AppColors.primaryL;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: textSecondary),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.body.copyWith(color: textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Try again',
                style: AppTextStyles.label.copyWith(color: primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Neumorphic Bottom Navigation Bar ────────────────────────────────────────
// Design spec section 5.6: surface-raised, raised neumorphic, active dot in primary.

class _NeumorphicNav extends StatelessWidget {
  const _NeumorphicNav({
    required this.selectedIndex,
    required this.onTap,
    required this.isDark,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool isDark;

  static const _icons = [
    (outline: Icons.home_outlined,      filled: Icons.home_rounded),
    (outline: Icons.search_rounded,     filled: Icons.search_rounded),
    (outline: Icons.add_circle_outline, filled: Icons.add_circle_rounded),
    (outline: Icons.notifications_none_rounded, filled: Icons.notifications_rounded),
    (outline: Icons.person_outline_rounded,     filled: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primaryD : AppColors.primaryL;
    final textSecondary = isDark ? AppColors.textSecondaryD : AppColors.textSecondaryL;
    final shadowLight = isDark ? AppColors.shadowLightD : AppColors.shadowLightL;
    final shadowDark = isDark ? AppColors.shadowDarkD : AppColors.shadowDarkL;
    final bg = isDark ? AppColors.surfaceRaisedD : AppColors.surfaceRaisedL;
    final blur = isDark ? 12.0 : 14.0;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        boxShadow: [
          BoxShadow(color: shadowLight, offset: const Offset(-6, -6), blurRadius: blur),
          BoxShadow(color: shadowDark,  offset: const Offset(6, 6),   blurRadius: blur),
        ],
      ),
      padding: EdgeInsets.only(bottom: bottomPad, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_icons.length, (i) {
          final isActive = i == selectedIndex;
          final icon = isActive ? _icons[i].filled : _icons[i].outline;
          return Semantics(
            label: ['Home', 'Search', 'Create', 'Notifications', 'Profile'][i],
            button: true,
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 48,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 24, color: isActive ? primary : textSecondary),
                    const SizedBox(height: 4),
                    // Active indicator dot — 8dp in primary
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isActive ? 8 : 0,
                      height: isActive ? 8 : 0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? primary : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
