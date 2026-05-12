import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/pulso_theme_extension.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../auth/data/providers/auth_providers.dart';
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
    return Scaffold(
      extendBody: true,
      appBar: const _PulsoAppBar(),
      body: const _FeedBody(),
      bottomNavigationBar: _NeumorphicNav(
        selectedIndex: _selectedTab,
        onTap: (i) {
          if (i == 2) {
            context.push(AppRoutes.createPost);
            return;
          }
          if (i == 4) {
            final userId = ref.read(authStateChangesProvider).asData?.value?.id;
            if (userId != null) context.push(AppRoutes.profileFor(userId));
            return;
          }
          setState(() => _selectedTab = i);
        },
      ),
    );
  }
}

// ─── Top App Bar ─────────────────────────────────────────────────────────────

class _PulsoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _PulsoAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surface,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 20,
        right: 20,
      ),
      height: preferredSize.height + MediaQuery.of(context).padding.top,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Pulso',
            style: GoogleFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: cs.onSurface,
              height: 1.0,
            ),
          ),
          const Spacer(),
          Consumer(
            builder: (context, ref, _) {
              final mode = ref.watch(themeProvider);
              final isDark = mode == ThemeMode.dark;
              return GestureDetector(
                onTap: () => ref.read(themeProvider.notifier).toggle(),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    key: ValueKey(isDark),
                    size: 24,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Icon(Icons.notifications_none_rounded, size: 24, color: cs.onSurfaceVariant),
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
    final cs = Theme.of(context).colorScheme;

    return switch (feedState) {
      FeedInitial() => const _LoadingView(),
      FeedLoading()  => const _LoadingView(),
      FeedError(:final exception) => _ErrorView(
          message: exception.message,
          onRetry: () => ref.read(feedNotifierProvider.notifier).loadFeed(),
        ),
      FeedLoaded(:final posts) when posts.isEmpty => const _EmptyView(),
      FeedLoaded(:final posts) => RefreshIndicator(
          color: cs.primary,
          backgroundColor: cs.surfaceContainerHighest,
          onRefresh: () => ref.read(feedNotifierProvider.notifier).refresh(),
          child: ListView.builder(
            padding: EdgeInsets.only(
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 80,
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
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: 4,
      itemBuilder: (_, i) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

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
    final cs = Theme.of(context).colorScheme;
    final pulso = context.pulso;
    final base = cs.surfaceContainerHighest;
    final shimmer = pulso.primaryMuted.withValues(alpha: 0.2);

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
  const _EmptyView();

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
    final cs = Theme.of(context).colorScheme;
    final pulso = context.pulso;

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
                    colors: [pulso.primaryMuted, pulso.primaryMuted.withValues(alpha: 0)],
                  ),
                ),
                child: Icon(Icons.photo_library_outlined, size: 36, color: pulso.primaryMuted),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('No posts yet.', style: AppTextStyles.title.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(
            'Be the first to share a moment.',
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

// ─── Neumorphic Bottom Navigation Bar ────────────────────────────────────────

class _NeumorphicNav extends StatelessWidget {
  const _NeumorphicNav({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const _icons = [
    (outline: Icons.home_outlined,               filled: Icons.home_rounded),
    (outline: Icons.search_rounded,              filled: Icons.search_rounded),
    (outline: Icons.add_circle_outline,          filled: Icons.add_circle_rounded),
    (outline: Icons.notifications_none_rounded,  filled: Icons.notifications_rounded),
    (outline: Icons.person_outline_rounded,      filled: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pulso = context.pulso;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: pulso.shadowLight,
            offset: const Offset(-6, -6),
            blurRadius: pulso.shadowBlur,
          ),
          BoxShadow(
            color: pulso.shadowDark,
            offset: const Offset(6, 6),
            blurRadius: pulso.shadowBlur,
          ),
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
                    Icon(icon, size: 24, color: isActive ? cs.primary : cs.onSurfaceVariant),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isActive ? 8 : 0,
                      height: isActive ? 8 : 0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? cs.primary : Colors.transparent,
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
