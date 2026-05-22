import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/feed/domain/models/post.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/feed/presentation/screens/post_creation_screen.dart';
import '../../features/feed/presentation/screens/post_detail_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/domain/models/profile.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/view_user_profile_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
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

      // ── Home Shell ───────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.feed,
            builder: (context, state) => const FeedScreen(),
          ),
          GoRoute(
            path: AppRoutes.search,
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Post Creation (slides up from bottom) ────────────────────────────
      GoRoute(
        path: AppRoutes.createPost,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PostCreationScreen(),
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
              child: RepaintBoundary(child: child),
            );
          },
        ),
      ),

      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) =>
            EditProfileScreen(initialProfile: state.extra as Profile),
      ),
      GoRoute(
        path: AppRoutes.userProfile,
        builder: (context, state) => ViewUserProfileScreen(
          userId: state.pathParameters['userId']!,
        ),
      ),

      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),

      // ── Post Detail ──────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.postDetail,
        builder: (context, state) => PostDetailScreen(
          postId: state.pathParameters['postId']!,
          initialPost: state.extra as Post?,
        ),
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
