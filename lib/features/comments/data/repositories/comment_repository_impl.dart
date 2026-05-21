import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../domain/exceptions/comment_exception.dart';
import '../../domain/models/comment.dart';
import '../../domain/repositories/comment_repository.dart';

/// Implementation of CommentRepository backed by Supabase.
class CommentRepositoryImpl implements CommentRepository {
  CommentRepositoryImpl(this.client);

  final supabase.SupabaseClient client;

  static const String _commentSelect = 'id, post_id, user_id, body, created_at';

  @override
  Future<List<Comment>> fetchCommentsByPostId(String postId) async {
    try {
      final data = await client
          .from('comments')
          .select(_commentSelect)
          .eq('post_id', postId)
          .order('created_at', ascending: false);

      final rows = (data as List<dynamic>).cast<Map<String, dynamic>>();
      return _hydrateComments(rows);
    } on SocketException {
      throw const CommentFetchException('Network error.');
    } on TimeoutException {
      throw const CommentFetchException('Network error.');
    } on supabase.PostgrestException catch (error) {
      throw CommentFetchException(error.message);
    } catch (error) {
      throw UnknownCommentException(error.toString());
    }
  }

  @override
  Future<Comment> fetchCommentById(String commentId) async {
    try {
      final data = await client
          .from('comments')
          .select(_commentSelect)
          .eq('id', commentId)
          .single();

      final comment = await _hydrateComments([
        Map<String, dynamic>.from(data),
      ]);
      return comment.first;
    } on SocketException {
      throw const CommentFetchException('Network error.');
    } on TimeoutException {
      throw const CommentFetchException('Network error.');
    } on supabase.PostgrestException catch (error) {
      throw CommentFetchException(error.message);
    } catch (error) {
      throw UnknownCommentException(error.toString());
    }
  }

  @override
  Future<Comment> createComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    if (userId.isEmpty) {
      throw const CommentCreationException('You must be signed in to comment.');
    }

    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw const CommentCreationException('Comment cannot be empty.');
    }

    try {
      final data = await client
          .from('comments')
          .insert({
            'post_id': postId,
            'user_id': userId,
            'body': trimmed,
          })
          .select(_commentSelect)
          .single();

      final comment = await _hydrateComments([
        Map<String, dynamic>.from(data),
      ]);
      return comment.first;
    } on SocketException {
      throw const CommentCreationException('Network error.');
    } on TimeoutException {
      throw const CommentCreationException('Network error.');
    } on supabase.PostgrestException catch (error) {
      throw CommentCreationException(error.message);
    } catch (error) {
      throw UnknownCommentException(error.toString());
    }
  }

  @override
  Future<void> deleteComment(String commentId) async {
    try {
      await client.from('comments').delete().eq('id', commentId);
    } on SocketException {
      throw const CommentDeletionException('Network error.');
    } on TimeoutException {
      throw const CommentDeletionException('Network error.');
    } on supabase.PostgrestException catch (error) {
      throw CommentDeletionException(error.message);
    } catch (error) {
      throw UnknownCommentException(error.toString());
    }
  }

  @override
  Future<void> toggleCommentLike({
    required String commentId,
    required String userId,
    required bool currentlyLiked,
  }) async {
    return;
  }

  Future<List<Comment>> _hydrateComments(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return [];

    final userIds = rows
        .map((row) => row['user_id'] as String)
        .toSet()
        .toList();

    Map<String, Map<String, dynamic>> profilesById = {};
    if (userIds.isNotEmpty) {
      final profiles = await client
          .from('profiles')
          .select('id, username, avatar_url')
          .inFilter('id', userIds);

      profilesById = {
        for (final profile in (profiles as List<dynamic>))
          (profile as Map<String, dynamic>)['id'] as String: profile,
      };
    }

    return rows.map((row) {
      final profile = profilesById[row['user_id'] as String];
      final enriched = {
        ...row,
        if (profile != null) 'username': profile['username'],
        if (profile != null) 'avatar_url': profile['avatar_url'],
      };
      return Comment.fromMap(enriched);
    }).toList();
  }
}
