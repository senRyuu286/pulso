import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/feed/data/providers/feed_providers.dart';
import '../../../../features/feed/domain/models/post.dart';
import '../../../../features/feed/domain/repositories/feed_repository.dart';
import '../../data/providers/social_providers.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/social_repository.dart';

// ─── Per-user profile state ───────────────────────────────────────────────────

sealed class ProfileState {
  const ProfileState();
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

final class ProfileLoaded extends ProfileState {
  const ProfileLoaded({required this.profile, required this.posts});

  final UserProfile profile;
  final List<Post> posts;
}

final class ProfileError extends ProfileState {
  const ProfileError(this.message);

  final String message;
}

// ─── Global notifier keyed by userId via a map ────────────────────────────────
//
// Mirrors the FollowNotifier pattern — avoids NotifierProvider.family
// whose API changed in Riverpod 3.x.

typedef ProfileMap = Map<String, ProfileState>;

final profileNotifierProvider =
    NotifierProvider<ProfileNotifier, ProfileMap>(ProfileNotifier.new);

class ProfileNotifier extends Notifier<ProfileMap> {
  @override
  ProfileMap build() => {};

  SocialRepository get _social => ref.read(socialRepositoryProvider);
  FeedRepository get _feed => ref.read(feedRepositoryProvider);

  /// Loads profile if not already cached.
  Future<void> load(String userId) async {
    if (state[userId] is ProfileLoaded) return;
    await _fetch(userId);
  }

  /// Force-reloads profile (e.g. pull-to-refresh).
  Future<void> refresh(String userId) => _fetch(userId);

  Future<void> _fetch(String userId) async {
    state = {...state, userId: const ProfileLoading()};
    try {
      final results = await Future.wait<dynamic>([
        _social.getUserProfile(userId),
        _feed.fetchUserPosts(userId),
      ]);
      state = {
        ...state,
        userId: ProfileLoaded(
          profile: results[0] as UserProfile,
          posts: results[1] as List<Post>,
        ),
      };
    } catch (e) {
      state = {...state, userId: ProfileError(e.toString())};
    }
  }

  /// Optimistically adjusts the follower count by [delta] (+1 or -1).
  /// Called by the profile screen when the follow button is toggled.
  void adjustFollowerCount(String userId, int delta) {
    final current = state[userId];
    if (current is! ProfileLoaded) return;
    state = {
      ...state,
      userId: ProfileLoaded(
        profile: current.profile.copyWith(
          followersCount: current.profile.followersCount + delta,
        ),
        posts: current.posts,
      ),
    };
  }
}
