import '../../domain/models/comment.dart';
import '../../domain/repositories/comment_repository.dart';

/// Implementation of CommentRepository.
/// TODO: Implement with Supabase client integration.
class CommentRepositoryImpl implements CommentRepository {
  @override
  Future<List<Comment>> fetchCommentsByPostId(String postId) async {
    // TODO: Implement fetch logic from Supabase
    throw UnimplementedError('fetchCommentsByPostId not implemented');
  }

  @override
  Future<Comment> createComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    // TODO: Implement create logic to Supabase
    throw UnimplementedError('createComment not implemented');
  }

  @override
  Future<void> deleteComment(String commentId) async {
    // TODO: Implement delete logic from Supabase
    throw UnimplementedError('deleteComment not implemented');
  }

  @override
  Future<void> toggleCommentLike({
    required String commentId,
    required String userId,
    required bool currentlyLiked,
  }) async {
    // TODO: Implement toggle like logic on Supabase
    throw UnimplementedError('toggleCommentLike not implemented');
  }
}
