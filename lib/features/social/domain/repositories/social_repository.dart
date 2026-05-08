abstract class SocialRepository {
  Future<void> follow({
    required String followerId,
    required String followingId,
  });

  Future<void> unfollow({
    required String followerId,
    required String followingId,
  });

  Future<bool> isFollowing({
    required String followerId,
    required String followingId,
  });

  Future<int> followerCount(String userId);

  Future<int> followingCount(String userId);
}
