import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.asData?.value;

	return GoRouter(
		initialLocation: AppRoutes.login,
		routes: [
			GoRoute(
				path: AppRoutes.login,
				builder: (context, state) => const LoginScreen(),
			),
			GoRoute(
				path: AppRoutes.register,
				builder: (context, state) => const RegisterScreen(),
			),
			GoRoute(
				path: AppRoutes.feed,
				builder: (context, state) => const _FeedScreen(),
			),
		],
		redirect: (context, state) {
			if (authState.isLoading) {
				return null;
			}

      final isAuthed = user != null;
      final isOnAuthRoute = AppRoutes.isAuthRoute(state.matchedLocation);

			if (!isAuthed && !isOnAuthRoute) {
				return AppRoutes.login;
			}

			if (isAuthed && isOnAuthRoute) {
				return AppRoutes.feed;
			}

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
