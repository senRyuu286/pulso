import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../domain/models/user_profile.dart';
import '../../domain/repositories/social_repository.dart';

class SocialRepositoryImpl implements SocialRepository {
  SocialRepositoryImpl(this.client);

  final supabase.SupabaseClient client;

  @override
  Future<void> follow({
    required String followerId,
    required String followingId,
  }) async {
    try {
      await client.from('follows').upsert(
        {
          'follower_id': followerId,
          'following_id': followingId,
        },
        onConflict: 'follower_id,following_id',
      );
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    }
  }

  @override
  Future<void> unfollow({
    required String followerId,
    required String followingId,
  }) async {
    try {
      await client
          .from('follows')
          .delete()
          .eq('follower_id', followerId)
          .eq('following_id', followingId);
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    }
  }

  @override
  Future<bool> isFollowing({
    required String followerId,
    required String followingId,
  }) async {
    try {
      final data = await client
          .from('follows')
          .select('follower_id')
          .eq('follower_id', followerId)
          .eq('following_id', followingId)
          .maybeSingle();
      return data != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<int> followerCount(String userId) async {
    try {
      final data = await client
          .from('follows')
          .select('follower_id')
          .eq('following_id', userId);
      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<int> followingCount(String userId) async {
    try {
      final data = await client
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId);
      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<UserProfile> getUserProfile(String userId) async {
    try {
      final results = await Future.wait<dynamic>([
        client
            .from('profiles')
            .select('id, username, avatar_url')
            .eq('id', userId)
            .single(),
        client.from('posts').select('id').eq('user_id', userId),
        client.from('follows').select('follower_id').eq('following_id', userId),
        client.from('follows').select('following_id').eq('follower_id', userId),
      ]);

      final profile = results[0] as Map<String, dynamic>;
      return UserProfile(
        id: profile['id'] as String,
        username: profile['username'] as String,
        avatarUrl: profile['avatar_url'] as String?,
        postsCount: (results[1] as List).length,
        followersCount: (results[2] as List).length,
        followingCount: (results[3] as List).length,
      );
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    }
  }
}
