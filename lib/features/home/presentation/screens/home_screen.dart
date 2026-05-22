import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../notifications/presentation/providers/notification_notifier.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _indexFromLocation(location);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      extendBody: true,
      appBar: const _PulsoAppBar(),
      body: widget.child,
      bottomNavigationBar: _BottomNav(
        selectedIndex: selectedIndex,
        unreadNotificationCount: unreadCount,
        onTap: (i) {
          if (i == 2) {
            context.push(AppRoutes.createPost);
            return;
          }
          switch (i) {
            case 0:
              context.go(AppRoutes.feed);
              break;
            case 1:
              context.go(AppRoutes.search);
              break;
            case 3:
              context.go(AppRoutes.notifications);
              break;
            case 4:
              context.go(AppRoutes.profile);
              break;
            default:
              context.go(AppRoutes.feed);
          }
        },
      ),
    );
  }

  int _indexFromLocation(String location) {
    if (location.startsWith(AppRoutes.search)) {
      return 1;
    }
    if (location.startsWith(AppRoutes.notifications)) {
      return 3;
    }
    if (location.startsWith(AppRoutes.profile)) {
      return 4;
    }
    return 0;
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
            style: AppTextStyles.headline.copyWith(color: cs.primary),
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
        ],
      ),
    );
  }
}

// ─── Bottom Navigation Bar ───────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.selectedIndex,
    required this.unreadNotificationCount,
    required this.onTap,
  });

  final int selectedIndex;
  final int unreadNotificationCount;
  final ValueChanged<int> onTap;

  static const _icons = [
    (outline: Icons.home_outlined, filled: Icons.home_rounded),
    (outline: Icons.explore_outlined, filled: Icons.explore_rounded),
    (outline: Icons.add_rounded, filled: Icons.add_rounded),
    (outline: Icons.notifications_none_rounded, filled: Icons.notifications_rounded),
    (outline: Icons.person_outline_rounded, filled: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outline.withValues(alpha: 0.3), width: 0.5),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottomPad, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_icons.length, (i) {
          if (i == 2) {
            return Semantics(
              label: 'Create',
              button: true,
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            );
          }

          final isActive = i == selectedIndex;
          final icon = isActive ? _icons[i].filled : _icons[i].outline;
          final showBadge = i == 3 && unreadNotificationCount > 0;

          return Semantics(
            label: ['Home', 'Search', '', 'Notifications', 'Profile'][i],
            button: true,
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 48,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          icon,
                          size: 24,
                          color: isActive ? cs.primary : cs.onSurfaceVariant,
                        ),
                        if (showBadge)
                          Positioned(
                            top: -4,
                            right: -6,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                              decoration: BoxDecoration(
                                color: cs.error,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unreadNotificationCount > 9
                                    ? '9+'
                                    : '$unreadNotificationCount',
                                style: AppTextStyles.caption.copyWith(
                                  color: cs.onError,
                                  fontSize: 9,
                                  height: 1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 2,
                      width: isActive ? 20.0 : 0.0,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(1),
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
