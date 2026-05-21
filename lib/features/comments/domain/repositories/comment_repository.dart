import '../models/comment.dart';

/// Abstract repository for comment operations.
abstract interface class CommentRepository {
  /// Fetch all comments for a specific post.
  Future<List<Comment>> fetchCommentsByPostId(String postId);

  /// Create a new comment on a post.
  Future<Comment> createComment({
    required String postId,
    required String userId,
    required String content,
  });

  /// Fetch a single comment by ID.
  Future<Comment> fetchCommentById(String commentId);

  /// Delete a comment by ID.
  Future<void> deleteComment(String commentId);

  /// Toggle like on a comment.
  Future<void> toggleCommentLike({
    required String commentId,
    required String userId,
    required bool currentlyLiked,
  });
}
