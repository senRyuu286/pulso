import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../domain/exceptions/feed_exception.dart';
import '../../domain/models/post.dart';
import '../../domain/repositories/feed_repository.dart';

class FeedRepositoryImpl implements FeedRepository {
  FeedRepositoryImpl(this.client);

  final supabase.SupabaseClient client;

  static const String _postSelect = '''
    *,
    likes!fk_likes_posts(user_id),
    reposts!fk_reposts_posts(user_id),
    author:profiles!fk_posts_profiles(id, username, avatar_url)
  ''';

  @override
  Future<List<Post>> fetchFeed({int page = 0, int pageSize = 20}) async {
    try {
      final currentUserId = client.auth.currentUser?.id ?? '';
      final from = page * pageSize;
      final to = from + pageSize - 1;

      final data = await client
          .from('posts')
          .select(_postSelect)
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
  Future<List<Post>> fetchUserPosts(String userId,
      {int page = 0, int pageSize = 30}) async {
    try {
      final currentUserId = client.auth.currentUser?.id ?? '';

      final results = await Future.wait<dynamic>([
        client
            .from('posts')
            .select(_postSelect)
            .eq('user_id', userId)
            .order('created_at', ascending: false),
        client.from('reposts').select('post_id').eq('user_id', userId),
        client
            .from('profiles')
            .select('username')
            .eq('id', userId)
            .maybeSingle(),
      ]);

      final ownPosts = (results[0] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((row) => Post.fromMap(row, currentUserId: currentUserId))
          .toList();

      final repostIds = (results[1] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((r) => r['post_id'] as String)
          .toList();

      final reposterUsername =
          (results[2] as Map<String, dynamic>?)?['username'] as String? ?? '';

      List<Post> repostedPosts = [];
      if (repostIds.isNotEmpty) {
        // Exclude posts the user already owns to avoid duplicates
        final ownIds = ownPosts.map((p) => p.id).toSet();
        final foreignIds =
            repostIds.where((id) => !ownIds.contains(id)).toList();
        if (foreignIds.isNotEmpty) {
          final repostedData = await client
              .from('posts')
              .select(_postSelect)
              .inFilter('id', foreignIds);

          repostedPosts = (repostedData as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .map((row) => Post.fromMap(
                    {...row, 'reposted_by_username': reposterUsername},
                    currentUserId: currentUserId,
                  ))
              .toList();
        }
      }

      final allPosts = [...ownPosts, ...repostedPosts]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final from = page * pageSize;
      if (from >= allPosts.length) return [];
      final to = min(from + pageSize, allPosts.length);
      return allPosts.sublist(from, to);
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
      final filename = '${_generateUuidV4()}.jpg';
      final storagePath = '$userId/$filename';

      await client.storage.from('posts').upload(
            storagePath,
            image,
            fileOptions: const supabase.FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      final imageUrl = client.storage.from('posts').getPublicUrl(storagePath);

      final data = await client
          .from('posts')
          .insert({
            'user_id': userId,
            'image_url': imageUrl,
            'caption': caption,
          })
          .select(_postSelect)
          .single();

      final post = Post.fromMap(data, currentUserId: userId);

      // Fan out notifications to followers (best-effort — does not fail post creation)
      try {
        await _fanOutNotifications(postId: post.id, actorId: userId);
      } catch (_) {}

      return post;
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
  Future<void> deletePost(String postId) async {
    try {
      await client.from('posts').delete().eq('id', postId);
    } on SocketException {
      throw const NetworkFeedException();
    } on TimeoutException {
      throw const NetworkFeedException();
    } catch (error) {
      throw UnknownFeedException(_messageFromError(error));
    }
  }

  @override
  Future<void> repost({
    required String postId,
    required String userId,
    required bool currentlyReposted,
  }) async {
    try {
      if (currentlyReposted) {
        await client
            .from('reposts')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
      } else {
        await client.from('reposts').upsert(
          {'post_id': postId, 'user_id': userId},
          onConflict: 'post_id,user_id',
        );
      }
    } on SocketException {
      throw const NetworkFeedException();
    } on TimeoutException {
      throw const NetworkFeedException();
    } catch (error) {
      throw UnknownFeedException(_messageFromError(error));
    }
  }

  @override
  Future<Post> fetchPostById(String postId) async {
    try {
      final currentUserId = client.auth.currentUser?.id ?? '';
      final data = await client
          .from('posts')
          .select(_postSelect)
          .eq('id', postId)
          .single();
      return Post.fromMap(data, currentUserId: currentUserId);
    } on SocketException {
      throw const NetworkFeedException();
    } on TimeoutException {
      throw const NetworkFeedException();
    } catch (error) {
      throw UnknownFeedException(_messageFromError(error));
    }
  }

  Future<void> _fanOutNotifications({
    required String postId,
    required String actorId,
  }) async {
    final followersData = await client
        .from('follows')
        .select('follower_id')
        .eq('following_id', actorId);

    final followerIds = (followersData as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((f) => f['follower_id'] as String)
        .toList();

    if (followerIds.isEmpty) return;

    final notifications = followerIds
        .map((followerId) => {
              'recipient_id': followerId,
              'actor_id': actorId,
              'post_id': postId,
              'type': 'new_post',
              'is_read': false,
            })
        .toList();

    await client.from('notifications').insert(notifications);
  }

  String _messageFromError(Object error) {
    final text = error.toString();
    return text.isEmpty ? 'Something went wrong.' : text;
  }

  String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }
}
