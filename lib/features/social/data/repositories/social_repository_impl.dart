import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

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
      await client.from('follows').upsert({
        'follower_id': followerId,
        'following_id': followingId,
      });
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
}
