class Profile {
  const Profile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.bio,
    required this.avatarUrl,
    required this.postCount,
    required this.followerCount,
    required this.followingCount,
    required this.createdAt,
  });

  final String id;
  final String username;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final int postCount;
  final int followerCount;
  final int followingCount;
  final DateTime createdAt;

  Profile copyWith({
    String? id,
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
    int? postCount,
    int? followerCount,
    int? followingCount,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      postCount: postCount ?? this.postCount,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: (json['username'] as String?) ?? '',
      displayName: json['display_name'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      postCount: (json['postCount'] as int?) ?? (json['post_count'] as int?) ?? 0,
      followerCount:
          (json['followerCount'] as int?) ?? (json['follower_count'] as int?) ?? 0,
      followingCount:
          (json['followingCount'] as int?) ?? (json['following_count'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'bio': bio,
      'avatar_url': avatarUrl,
      'post_count': postCount,
      'follower_count': followerCount,
      'following_count': followingCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Profile &&
        other.id == id &&
        other.username == username &&
      other.displayName == displayName &&
        other.bio == bio &&
        other.avatarUrl == avatarUrl &&
        other.postCount == postCount &&
        other.followerCount == followerCount &&
        other.followingCount == followingCount &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        username,
      displayName,
        bio,
        avatarUrl,
        postCount,
        followerCount,
        followingCount,
        createdAt,
      );
}
