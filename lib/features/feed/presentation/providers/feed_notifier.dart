import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/data/providers/auth_providers.dart';
import '../../data/providers/feed_providers.dart';
import '../../domain/exceptions/feed_exception.dart';
import '../../domain/models/post.dart';
import '../../domain/repositories/feed_repository.dart';

// ─── Feed State ───────────────────────────────────────────────────────────────

sealed class FeedState {
  const FeedState();
}

final class FeedInitial extends FeedState {
  const FeedInitial();
}

final class FeedLoading extends FeedState {
  const FeedLoading();
}

final class FeedLoaded extends FeedState {
  const FeedLoaded(this.posts);

  final List<Post> posts;
}

final class FeedError extends FeedState {
  const FeedError(this.exception);

  final FeedException exception;
}

// ─── Feed Notifier ────────────────────────────────────────────────────────────

final feedNotifierProvider = NotifierProvider<FeedNotifier, FeedState>(
  FeedNotifier.new,
);

class FeedNotifier extends Notifier<FeedState> {
  @override
  FeedState build() => const FeedInitial();

  FeedRepository get _repository => ref.read(feedRepositoryProvider);

  String get _userId =>
      ref.read(supabaseClientProvider).auth.currentUser?.id ?? '';

  Future<void> loadFeed() async {
    state = const FeedLoading();
    try {
      final posts = await _repository.fetchFeed();
      state = FeedLoaded(posts);
    } on FeedException catch (e) {
      state = FeedError(e);
    } catch (e) {
      state = FeedError(UnknownFeedException(e.toString()));
    }
  }

  Future<void> refresh() async {
    // Keep current content visible while refreshing
    try {
      final posts = await _repository.fetchFeed();
      state = FeedLoaded(posts);
    } on FeedException catch (e) {
      state = FeedError(e);
    } catch (e) {
      state = FeedError(UnknownFeedException(e.toString()));
    }
  }

  /// Optimistic like toggle with rollback on Supabase error.
  Future<void> toggleLike(Post post) async {
    final snapshot = state;
    if (snapshot is! FeedLoaded) return;

    // Apply optimistic update immediately
    final optimistic = snapshot.posts.map((p) {
      if (p.id != post.id) return p;
      return p.copyWith(
        isLikedByMe: !p.isLikedByMe,
        likesCount: p.isLikedByMe ? p.likesCount - 1 : p.likesCount + 1,
      );
    }).toList();
    state = FeedLoaded(optimistic);

    try {
      await _repository.toggleLike(
        postId: post.id,
        userId: _userId,
        currentlyLiked: post.isLikedByMe,
      );
    } catch (_) {
      // Rollback to pre-tap state on any error
      state = snapshot;
    }
  }

  /// Called by PostCreationNotifier after a successful upload.
  void prependPost(Post post) {
    final current = state;
    final existing = current is FeedLoaded ? current.posts : <Post>[];
    state = FeedLoaded([post, ...existing]);
  }
}

// ─── Post Creation State ──────────────────────────────────────────────────────

sealed class PostCreationState {
  const PostCreationState();
}

final class PostCreationIdle extends PostCreationState {
  const PostCreationIdle();
}

final class PostCreationLoading extends PostCreationState {
  const PostCreationLoading();
}

final class PostCreationSuccess extends PostCreationState {
  const PostCreationSuccess();
}

final class PostCreationError extends PostCreationState {
  const PostCreationError(this.exception);

  final FeedException exception;
}

// ─── Post Creation Notifier ───────────────────────────────────────────────────

final postCreationNotifierProvider =
    NotifierProvider<PostCreationNotifier, PostCreationState>(
  PostCreationNotifier.new,
);

class PostCreationNotifier extends Notifier<PostCreationState> {
  @override
  PostCreationState build() => const PostCreationIdle();

  FeedRepository get _repository => ref.read(feedRepositoryProvider);

  String get _userId =>
      ref.read(supabaseClientProvider).auth.currentUser?.id ?? '';

  Future<void> submit({required File image, String? caption}) async {
    state = const PostCreationLoading();
    try {
      final post = await _repository.createPost(
        image: image,
        caption: caption,
        userId: _userId,
      );
      // Prepend new post to live feed
      ref.read(feedNotifierProvider.notifier).prependPost(post);
      state = const PostCreationSuccess();
    } on FeedException catch (e) {
      state = PostCreationError(e);
    } catch (e) {
      state = PostCreationError(UnknownFeedException(e.toString()));
    }
  }

  void reset() => state = const PostCreationIdle();
}
