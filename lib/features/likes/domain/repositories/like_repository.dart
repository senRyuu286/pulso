import '../models/like_snapshot.dart';

abstract class LikeRepository {
  Future<LikeSnapshot> fetchLikeSnapshot({
    required String postId,
    required String userId,
  });

  Future<void> toggleLike({
    required String postId,
    required String userId,
    required bool currentlyLiked,
  });
}
