import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final commentNotifierProvider = NotifierProvider.family<
    CommentNotifier,
    CommentState,
    String>(
  CommentNotifier.new,
);

class CommentNotifier extends Notifier<CommentState> {
  late String postId;

  @override
  CommentState build(String postIdParam) {
    postId = postIdParam;
    return const CommentInitial();
  }

  CommentRepository get _repository => ref.read(commentRepositoryProvider);

  String get _userId =>
      ref.read(supabaseClientProvider).auth.currentUser?.id ?? '';

  Future<void> loadComments() async {
    state = const CommentLoading();
    try {
      final comments = await _repository.fetchCommentsByPostId(postId);
      state = CommentLoaded(comments);
    } on CommentException catch (e) {
      state = CommentError(e);
    } catch (e) {
      state = CommentError(UnknownCommentException(e.toString()));
    }
  }

  Future<void> addComment(String content) async {
    final current = state;
    if (current is! CommentLoaded) return;

    try {
      final newComment = await _repository.createComment(
        postId: postId,
        userId: _userId,
        content: content,
      );
      state = CommentLoaded([newComment, ...current.comments]);
    } on CommentException catch (e) {
      state = CommentError(e);
    } catch (e) {
      state = CommentError(UnknownCommentException(e.toString()));
    }
  }

  Future<void> toggleCommentLike(Comment comment) async {
    final snapshot = state;
    if (snapshot is! CommentLoaded) return;

    // Optimistic update
    final optimistic = snapshot.comments.map((c) {
      if (c.id != comment.id) return c;
      return c.copyWith(
        isLikedByMe: !c.isLikedByMe,
        likesCount: c.isLikedByMe ? c.likesCount - 1 : c.likesCount + 1,
      );
    }).toList();
    state = CommentLoaded(optimistic);

    try {
      await _repository.toggleCommentLike(
        commentId: comment.id,
        userId: _userId,
        currentlyLiked: comment.isLikedByMe,
      );
    } catch (_) {
      // Rollback on error
      state = snapshot;
    }
  }

  Future<void> deleteComment(String commentId) async {
    final current = state;
    if (current is! CommentLoaded) return;

    try {
      await _repository.deleteComment(commentId);
      state = CommentLoaded(
        current.comments.where((c) => c.id != commentId).toList(),
      );
    } on CommentException catch (e) {
      state = CommentError(e);
    } catch (e) {
      state = CommentError(UnknownCommentException(e.toString()));
    }
  }
}
