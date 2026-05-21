class Post {
  const Post({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.createdAt,
    required this.likesCount,
    required this.isLikedByMe,
    required this.repostsCount,
    required this.isRepostedByMe,
    this.caption,
    this.username,
    this.avatarUrl,
    this.repostedByUsername,
  });

  final String id;
  final String userId;
  final String imageUrl;
  final String? caption;
  final DateTime createdAt;
  final int likesCount;
  final bool isLikedByMe;
  final int repostsCount;
  final bool isRepostedByMe;
  final String? username;
  final String? avatarUrl;
  final String? repostedByUsername;

  factory Post.fromMap(Map<String, dynamic> map, {required String currentUserId}) {
    final likes = (map['likes'] as List?) ?? [];
    final reposts = (map['reposts'] as List?) ?? [];
    final profile = map['author'] as Map<String, dynamic>?;
    return Post(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      imageUrl: map['image_url'] as String,
      caption: map['caption'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      likesCount: likes.length,
      isLikedByMe: likes.any((l) => (l as Map)['user_id'] == currentUserId),
      repostsCount: reposts.length,
      isRepostedByMe: reposts.any((r) => (r as Map)['user_id'] == currentUserId),
      username: profile?['username'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
      repostedByUsername: map['reposted_by_username'] as String?,
    );
  }

  Post copyWith({
    int? likesCount,
    bool? isLikedByMe,
    int? repostsCount,
    bool? isRepostedByMe,
    String? repostedByUsername,
  }) {
    return Post(
      id: id,
      userId: userId,
      imageUrl: imageUrl,
      caption: caption,
      createdAt: createdAt,
      likesCount: likesCount ?? this.likesCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      repostsCount: repostsCount ?? this.repostsCount,
      isRepostedByMe: isRepostedByMe ?? this.isRepostedByMe,
      username: username,
      avatarUrl: avatarUrl,
      repostedByUsername: repostedByUsername ?? this.repostedByUsername,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Post && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
