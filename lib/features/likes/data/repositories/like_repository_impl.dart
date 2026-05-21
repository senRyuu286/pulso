import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../domain/models/like_snapshot.dart';
import '../../domain/repositories/like_repository.dart';

class LikeRepositoryImpl implements LikeRepository {
  LikeRepositoryImpl(this.client);

  final supabase.SupabaseClient client;

  @override
  Future<LikeSnapshot> fetchLikeSnapshot({
    required String postId,
    required String userId,
  }) async {
    try {
      final data = await client
          .from('likes')
          .select('user_id')
          .eq('post_id', postId);

      final rows = data as List<dynamic>;
      final count = rows.length;
      final isLiked = rows.any((row) {
        final map = row as Map<String, dynamic>;
        return map['user_id'] == userId;
      });

      return LikeSnapshot(count: count, isLikedByMe: isLiked);
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
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
        await client.from('likes').upsert(
          {
            'post_id': postId,
            'user_id': userId,
          },
          onConflict: 'post_id,user_id',
        );
      }
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    }
  }
}
