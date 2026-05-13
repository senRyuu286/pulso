import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../domain/exceptions/feed_exception.dart';
import '../../domain/models/post.dart';
import '../../domain/repositories/feed_repository.dart';

class FeedRepositoryImpl implements FeedRepository {
  FeedRepositoryImpl(this.client);

  final supabase.SupabaseClient client;

  @override
  Future<List<Post>> fetchFeed({int page = 0, int pageSize = 20}) async {
    try {
      final currentUserId = client.auth.currentUser?.id ?? '';
      final from = page * pageSize;
      final to = from + pageSize - 1;

      final data = await client
          .from('posts')
          .select('''
            *,
            likes(user_id),
            author:profiles!posts_user_id_fkey(id, username, avatar_url)
          ''')
          .order('created_at', ascending: false)
          .range(from, to);

      return (data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((row) => Post.fromMap(row, currentUserId: currentUserId))
          .toList();
    } on SocketException {
      throw const NetworkFeedException();
    } on TimeoutException {
      throw const NetworkFeedException();
    } catch (error) {
      throw UnknownFeedException(_messageFromError(error));
    }
  }

  @override
  Future<List<Post>> fetchUserPosts(String userId, {int page = 0, int pageSize = 30}) async {
    try {
      final currentUserId = client.auth.currentUser?.id ?? '';
      final from = page * pageSize;
      final to = from + pageSize - 1;

      final data = await client
          .from('posts')
          .select('''
            *,
            likes(user_id),
            author:profiles!posts_user_id_fkey(id, username, avatar_url)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(from, to);

      return (data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((row) => Post.fromMap(row, currentUserId: currentUserId))
          .toList();
    } on SocketException {
      throw const NetworkFeedException();
    } on TimeoutException {
      throw const NetworkFeedException();
    } catch (error) {
      throw UnknownFeedException(_messageFromError(error));
    }
  }

  @override
  Future<Post> createPost({
    required File image,
    required String? caption,
    required String userId,
  }) async {
    try {
      // Use millisecond timestamp as unique filename — no UUID package needed
      final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = '$userId/$filename';

      await client.storage.from('post-images').upload(
            storagePath,
            image,
            fileOptions: const supabase.FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      final imageUrl =
          client.storage.from('post-images').getPublicUrl(storagePath);

      final data = await client
          .from('posts')
          .insert({
            'user_id': userId,
            'image_url': imageUrl,
            'caption': caption,
          })
          .select('''
            *,
            likes(user_id),
            author:profiles!posts_user_id_fkey(id, username, avatar_url)
          ''')
          .single();

      return Post.fromMap(data, currentUserId: userId);
    } on SocketException {
      throw const NetworkFeedException();
    } on TimeoutException {
      throw const NetworkFeedException();
    } on supabase.StorageException catch (e) {
      throw UploadFeedException(e.message);
    } catch (error) {
      throw UnknownFeedException(_messageFromError(error));
    }
  }

  @override
  Future<void> toggleLike({
    required String postId,
    required String userId,
    required bool currentlyLiked,
  }) async {
    try {
      if (currentlyLiked) {
        await client
            .from('likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
      } else {
        await client.from('likes').upsert({
          'post_id': postId,
          'user_id': userId,
        });
      }
    } on SocketException {
      throw const NetworkFeedException();
    } on TimeoutException {
      throw const NetworkFeedException();
    } catch (error) {
      throw UnknownFeedException(_messageFromError(error));
    }
  }

  String _messageFromError(Object error) {
    final text = error.toString();
    return text.isEmpty ? 'Something went wrong.' : text;
  }
}
