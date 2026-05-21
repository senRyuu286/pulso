import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../features/auth/data/providers/auth_providers.dart';
import '../../data/providers/comment_providers.dart';
import '../../domain/exceptions/comment_exception.dart';
import '../../domain/models/comment.dart';
import '../../domain/repositories/comment_repository.dart';

// ─── Comment State ───────────────────────────────────────────────────────────

sealed class CommentState {
  const CommentState();
}

final class CommentInitial extends CommentState {
  const CommentInitial();
}

final class CommentLoading extends CommentState {
  const CommentLoading();
}

final class CommentLoaded extends CommentState {
  const CommentLoaded(this.comments);

  final List<Comment> comments;
}

final class CommentError extends CommentState {
  const CommentError(this.exception);

  final CommentException exception;
}

// ─── Comment Notifier ──────────────────────────────────────────────────────────

typedef CommentMap = Map<String, CommentState>;
typedef CommentCountMap = Map<String, int>;

final commentNotifierProvider =
    NotifierProvider<CommentNotifier, CommentMap>(CommentNotifier.new);

class CommentNotifier extends Notifier<CommentMap> {
  final Map<String, RealtimeChannel> _channels = {};

  @override
  CommentMap build() {
    ref.onDispose(_dispose);
    return {};
  }

  CommentRepository get _repository => ref.read(commentRepositoryProvider);

  SupabaseClient get _client => ref.read(supabaseClientProvider);

  String get _userId => ref.read(supabaseClientProvider).auth.currentUser?.id ?? '';

  CommentState stateFor(String postId) =>
      state[postId] ?? const CommentInitial();

  void ensureLoaded(String postId) {
    final current = state[postId];
    if (current is CommentLoaded || current is CommentLoading) return;
    _subscribeToInserts(postId);
    Future.microtask(() => loadComments(postId));
  }

  Future<void> loadComments(String postId) async {
    state = {...state, postId: const CommentLoading()};
    try {
      final comments = await _repository.fetchCommentsByPostId(postId);
      state = {...state, postId: CommentLoaded(comments)};
    } on CommentException catch (e) {
      state = {...state, postId: CommentError(e)};
    } catch (e) {
      state = {...state, postId: CommentError(UnknownCommentException(e.toString()))};
    }
  }

  Future<void> addComment({required String postId, required String content}) async {
    final current = state[postId];
    final existing = current is CommentLoaded ? current.comments : <Comment>[];
    try {
      final newComment = await _repository.createComment(
        postId: postId,
        userId: _userId,
        content: content,
      );
      state = {...state, postId: CommentLoaded([newComment, ...existing])};
    } on CommentException catch (e) {
      state = {...state, postId: CommentError(e)};
    } catch (e) {
      state = {...state, postId: CommentError(UnknownCommentException(e.toString()))};
    }
  }

  Future<void> deleteComment({required String postId, required String commentId}) async {
    final current = state[postId];
    if (current is! CommentLoaded) return;

    try {
      await _repository.deleteComment(commentId);
      state = {
        ...state,
        postId: CommentLoaded(
          current.comments.where((c) => c.id != commentId).toList(),
        ),
      };
    } on CommentException catch (e) {
      state = {...state, postId: CommentError(e)};
    } catch (e) {
      state = {...state, postId: CommentError(UnknownCommentException(e.toString()))};
    }
  }

  Future<void> toggleCommentLike({required String postId, required Comment comment}) async {
    final snapshot = state[postId];
    if (snapshot is! CommentLoaded) return;

    final optimistic = snapshot.comments.map((c) {
      if (c.id != comment.id) return c;
      return c.copyWith(
        isLikedByMe: !c.isLikedByMe,
        likesCount: c.isLikedByMe ? c.likesCount - 1 : c.likesCount + 1,
      );
    }).toList();
    state = {...state, postId: CommentLoaded(optimistic)};

    try {
      await _repository.toggleCommentLike(
        commentId: comment.id,
        userId: _userId,
        currentlyLiked: comment.isLikedByMe,
      );
    } catch (_) {
      state = {...state, postId: snapshot};
    }
  }

  void clear(String postId) {
    _removeChannel(postId);
    final updated = {...state}..remove(postId);
    state = updated;
  }

  void _subscribeToInserts(String postId) {
    if (_channels.containsKey(postId)) return;
    final channel = _client.channel('post_comments_$postId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'comments',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'post_id',
          value: postId,
        ),
        callback: (payload) => _handleInsert(postId, payload),
      )
      ..subscribe();

    _channels[postId] = channel;
  }

  Future<void> _handleInsert(
    String postId,
    PostgresChangePayload payload,
  ) async {
    if (!ref.mounted) return;
    final newId = payload.newRecord['id'] as String?;
    if (newId == null) return;

    try {
      final comment = await _repository.fetchCommentById(newId);
      final current = state[postId];
      if (current is! CommentLoaded) return;
      if (current.comments.any((c) => c.id == comment.id)) return;
      state = {...state, postId: CommentLoaded([comment, ...current.comments])};
    } catch (_) {
      // Ignore realtime hydration failures.
    }
  }

  void _removeChannel(String postId) {
    final channel = _channels.remove(postId);
    if (channel == null) return;
    _client.removeChannel(channel);
  }

  void _dispose() {
    for (final entry in _channels.entries) {
      _client.removeChannel(entry.value);
    }
    _channels.clear();
  }
}

// ─── Comment Counts (Realtime) ───────────────────────────────────────────────

final commentCountNotifierProvider =
    NotifierProvider<CommentCountNotifier, CommentCountMap>(
  CommentCountNotifier.new,
);

class CommentCountNotifier extends Notifier<CommentCountMap> {
  RealtimeChannel? _channel;

  @override
  CommentCountMap build() {
    _subscribeToCounts();
    ref.onDispose(_dispose);
    return {};
  }

  SupabaseClient get _client => ref.read(supabaseClientProvider);

  int countFor(String postId) => state[postId] ?? 0;

  Future<void> ensureLoaded(String postId) async {
    if (state.containsKey(postId)) return;
    try {
      final data = await _client
          .from('comments')
          .select('id')
          .eq('post_id', postId);
      final count = (data as List<dynamic>).length;
      state = {...state, postId: count};
    } catch (_) {
      state = {...state, postId: 0};
    }
  }

  void _subscribeToCounts() {
    _channel = _client.channel('post_comments')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'comments',
        callback: (payload) => _bump(payload, 1),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'comments',
        callback: (payload) => _bump(payload, -1),
      )
      ..subscribe();
  }

  void _bump(PostgresChangePayload payload, int delta) {
    if (!ref.mounted) return;
    final postId = payload.newRecord['post_id'] as String? ??
        payload.oldRecord['post_id'] as String?;
    if (postId == null) return;
    final current = state[postId] ?? 0;
    final next = (current + delta).clamp(0, 1 << 31);
    state = {...state, postId: next};
  }

  void _dispose() {
    final channel = _channel;
    if (channel == null) return;
    _client.removeChannel(channel);
    _channel = null;
  }
}
