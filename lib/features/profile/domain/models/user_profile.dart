class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
  });

  final String id;
  final String username;
  final String? avatarUrl;
  final int postsCount;
  final int followersCount;
  final int followingCount;

  UserProfile copyWith({int? followersCount}) {
    return UserProfile(
      id: id,
      username: username,
      avatarUrl: avatarUrl,
      postsCount: postsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount,
    );
  }
}
