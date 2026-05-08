import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/providers/auth_providers.dart';
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

      // ── Post Creation ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.createPost,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PostCreationScreen(),
          transitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Slide up from bottom — natural "compose" gesture
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            );
          },
        ),
      ),

      // ── Profile ──────────────────────────────────────────────────────────
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

// Minimal profile placeholder — full profile screen is outside this sprint's scope.
class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(child: Text('Profile: $userId')),
    );
  }
}
