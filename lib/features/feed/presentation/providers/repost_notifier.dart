import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/providers/auth_providers.dart';
import '../../data/providers/feed_providers.dart';
import '../../domain/repositories/feed_repository.dart';

// ─── Repost State ─────────────────────────────────────────────────────────────

sealed class RepostState {
  const RepostState();
}

final class RepostInitial extends RepostState {
  const RepostInitial();
}

final class RepostLoaded extends RepostState {
  const RepostLoaded({required this.count, required this.isRepostedByMe});

  final int count;
  final bool isRepostedByMe;
}

typedef RepostMap = Map<String, RepostState>;

// ─── Repost Notifier ──────────────────────────────────────────────────────────

final repostNotifierProvider =
    NotifierProvider<RepostNotifier, RepostMap>(RepostNotifier.new);

class RepostNotifier extends Notifier<RepostMap> {
  @override
  RepostMap build() => {};

  FeedRepository get _repository => ref.read(feedRepositoryProvider);

  String get _userId =>
      ref.read(supabaseClientProvider).auth.currentUser?.id ?? '';

  RepostState stateFor(String postId) =>
      state[postId] ?? const RepostInitial();

  void ensureLoaded(String postId, {int? seedCount, bool? seedIsReposted}) {
    if (state.containsKey(postId)) return;
    state = {
      ...state,
      postId: RepostLoaded(
        count: seedCount ?? 0,
        isRepostedByMe: seedIsReposted ?? false,
      ),
    };
  }

  Future<void> toggleRepost(String postId) async {
    final current = state[postId];
    if (current is! RepostLoaded) return;

    final nextCount = (current.isRepostedByMe
            ? current.count - 1
            : current.count + 1)
        .clamp(0, 1 << 31);
    final optimistic = RepostLoaded(
      count: nextCount,
      isRepostedByMe: !current.isRepostedByMe,
    );
    state = {...state, postId: optimistic};

    try {
      await _repository.repost(
        postId: postId,
        userId: _userId,
        currentlyReposted: current.isRepostedByMe,
      );
    } catch (_) {
      state = {...state, postId: current};
    }
  }
}
