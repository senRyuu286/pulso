import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/providers/auth_providers.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/feed/presentation/screens/post_creation_screen.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.asData?.value;

  return GoRouter(
    initialLocation: AppRoutes.login,
    routes: [
      // ── Auth ─────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Feed ─────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.feed,
        builder: (context, state) => const FeedScreen(),
      ),

      // ── Post Creation (slides up from bottom) ────────────────────────────
      GoRoute(
        path: AppRoutes.createPost,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PostCreationScreen(),
          // 260ms easeOut feels instant; shorter than 350ms means less time
          // the transition has to run heavy paint work.
          transitionDuration: const Duration(milliseconds: 260),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              // RepaintBoundary: PostCreationScreen is rasterised once into a
              // GPU layer. Every animation tick just composites that layer at a
              // new offset — CustomPainter.paint() is never called mid-flight.
              child: RepaintBoundary(child: child),
            );
          },
        ),
      ),

      // ── Profile (placeholder — full implementation out of scope) ─────────
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          return _ProfilePlaceholder(userId: userId);
        },
      ),
    ],
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final isAuthed = user != null;
      final isOnAuthRoute = AppRoutes.isAuthRoute(state.matchedLocation);

      if (!isAuthed && !isOnAuthRoute) return AppRoutes.login;
      if (isAuthed && isOnAuthRoute) return AppRoutes.feed;

      return null;
    },
  );
});

class _ProfilePlaceholder extends ConsumerWidget {
  const _ProfilePlaceholder({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Center(child: Text('Profile: $userId')),
    );
  }
}
