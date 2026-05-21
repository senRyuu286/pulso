import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/data/providers/auth_providers.dart';
import '../../data/providers/like_providers.dart';
import '../../domain/repositories/like_repository.dart';

sealed class LikeState {
  const LikeState();
}

final class LikeInitial extends LikeState {
  const LikeInitial();
}

final class LikeLoading extends LikeState {
  const LikeLoading();
}

final class LikeLoaded extends LikeState {
  const LikeLoaded({required this.count, required this.isLikedByMe});

  final int count;
  final bool isLikedByMe;
}

final class LikeError extends LikeState {
  const LikeError(this.message);

  final String message;
}

typedef LikeMap = Map<String, LikeState>;

final likeNotifierProvider =
    NotifierProvider<LikeNotifier, LikeMap>(LikeNotifier.new);

class LikeNotifier extends Notifier<LikeMap> {
  RealtimeChannel? _channel;
  String? _lastUserId;

  @override
  LikeMap build() {
    _lastUserId = _userId;
    ref.listen(authStateChangesProvider, (previous, next) {
      final previousId = previous?.maybeWhen(
        data: (user) => user?.id,
        orElse: () => null,
      );
      final nextId = next.maybeWhen(
        data: (user) => user?.id,
        orElse: () => null,
      );
      if (previousId == nextId) return;
      _lastUserId = nextId;
      state = {};
    });
    _subscribeToLikes();
    ref.onDispose(_dispose);
    return {};
  }

  LikeRepository get _repository => ref.read(likeRepositoryProvider);

  SupabaseClient get _client => ref.read(supabaseClientProvider);

  String get _userId => ref.read(supabaseClientProvider).auth.currentUser?.id ?? '';

  LikeState stateFor(String postId) => state[postId] ?? const LikeInitial();

  void ensureLoaded(
    String postId, {
    int? seedCount,
    bool? seedIsLiked,
  }) {
    if (_lastUserId != _userId) {
      _lastUserId = _userId;
      state = {};
    }
    if (state.containsKey(postId)) return;

    if (seedCount != null || seedIsLiked != null) {
      state = {
        ...state,
        postId: LikeLoaded(
          count: seedCount ?? 0,
          isLikedByMe: seedIsLiked ?? false,
        ),
      };
    } else {
      state = {...state, postId: const LikeLoading()};
    }

    Future.microtask(() => loadLike(postId));
  }

  Future<void> loadLike(String postId) async {
    state = {...state, postId: const LikeLoading()};
    try {
      final snapshot = await _repository.fetchLikeSnapshot(
        postId: postId,
        userId: _userId,
      );
      state = {
        ...state,
        postId: LikeLoaded(
          count: snapshot.count,
          isLikedByMe: snapshot.isLikedByMe,
        ),
      };
    } catch (e) {
      state = {...state, postId: LikeError(e.toString())};
    }
  }

  Future<void> toggleLike(String postId) async {
    final current = state[postId];
    if (current is! LikeLoaded) return;

    final nextCount = (current.isLikedByMe
        ? current.count - 1
        : current.count + 1)
      .clamp(0, 1 << 31);
    final optimistic = LikeLoaded(
      count: nextCount,
      isLikedByMe: !current.isLikedByMe,
    );
    state = {...state, postId: optimistic};

    try {
      await _repository.toggleLike(
        postId: postId,
        userId: _userId,
        currentlyLiked: current.isLikedByMe,
      );
    } catch (_) {
      state = {...state, postId: current};
    }
  }

  void _subscribeToLikes() {
    _channel = _client.channel('posts_likes')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'likes',
        callback: (payload) => _handleLikeChange(payload, 1),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'likes',
        callback: (payload) => _handleLikeChange(payload, -1),
      )
      ..subscribe();
  }

  void _handleLikeChange(PostgresChangePayload payload, int delta) {
    if (!ref.mounted) return;
    final record = payload.newRecord.isNotEmpty
        ? payload.newRecord
        : payload.oldRecord;
    final postId = record['post_id'] as String?;
    if (postId == null) return;
    final userId = record['user_id'] as String?;

    final current = state[postId];
    final base = current is LikeLoaded
        ? current
        : const LikeLoaded(count: 0, isLikedByMe: false);

    final isMine = userId != null && userId == _userId;
    if (isMine) {
      final alreadyApplied = (delta > 0 && base.isLikedByMe) ||
          (delta < 0 && !base.isLikedByMe);
      if (alreadyApplied) return;
    }

    final nextCount = (base.count + delta).clamp(0, 1 << 31);
    final nextLiked = isMine ? delta > 0 : base.isLikedByMe;

    state = {
      ...state,
      postId: LikeLoaded(
        count: nextCount,
        isLikedByMe: nextLiked,
      ),
    };
  }

  void _dispose() {
    final channel = _channel;
    if (channel == null) return;
    _client.removeChannel(channel);
    _channel = null;
  }
}
