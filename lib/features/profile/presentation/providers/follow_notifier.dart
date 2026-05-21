import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/providers/auth_providers.dart';
import '../../data/providers/social_providers.dart';
import '../../domain/repositories/social_repository.dart';

// ─── Per-user state ───────────────────────────────────────────────────────────

sealed class FollowState {
  const FollowState();
}

final class FollowChecking extends FollowState {
  const FollowChecking();
}

final class FollowLoaded extends FollowState {
  const FollowLoaded({required this.isFollowing});

  final bool isFollowing;
}

final class FollowError extends FollowState {
  const FollowError(this.message);

  final String message;
}

// ─── Global notifier keyed by targetUserId via a map ─────────────────────────
//
// Avoids NotifierProvider.family (API changed in Riverpod 3.x).
// Each FollowButton calls load(targetUserId) once and then reads
// state[targetUserId] for its slice of state.

typedef FollowMap = Map<String, FollowState>;

final followNotifierProvider =
    NotifierProvider<FollowNotifier, FollowMap>(FollowNotifier.new);

class FollowNotifier extends Notifier<FollowMap> {
  @override
  FollowMap build() => {};

  SocialRepository get _repository => ref.read(socialRepositoryProvider);

  String get _currentUserId =>
      ref.read(supabaseClientProvider).auth.currentUser?.id ?? '';

  FollowState stateFor(String targetUserId) =>
      state[targetUserId] ?? const FollowChecking();

  /// Called once per FollowButton on first build to populate its slice.
  Future<void> load(String targetUserId) async {
    if (state.containsKey(targetUserId)) return; // already loaded or loading
    state = {...state, targetUserId: const FollowChecking()};
    try {
      final following = await _repository.isFollowing(
        followerId: _currentUserId,
        followingId: targetUserId,
      );
      state = {...state, targetUserId: FollowLoaded(isFollowing: following)};
    } catch (e) {
      state = {...state, targetUserId: FollowError(e.toString())};
    }
  }

  /// Optimistic toggle with rollback on Supabase error.
  Future<void> toggle(String targetUserId) async {
    final current = state[targetUserId];
    if (current is! FollowLoaded) return;

    final wasFollowing = current.isFollowing;
    state = {...state, targetUserId: FollowLoaded(isFollowing: !wasFollowing)};

    try {
      if (wasFollowing) {
        await _repository.unfollow(
          followerId: _currentUserId,
          followingId: targetUserId,
        );
      } else {
        await _repository.follow(
          followerId: _currentUserId,
          followingId: targetUserId,
        );
      }
    } catch (_) {
      // Rollback
      state = {...state, targetUserId: current};
    }
  }
}
