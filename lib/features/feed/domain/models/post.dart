class Post {
  const Post({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.createdAt,
    required this.likesCount,
    required this.isLikedByMe,
    this.caption,
    this.username,
    this.avatarUrl,
  });

  final String id;
  final String userId;
  final String imageUrl;
  final String? caption;
  final DateTime createdAt;
  final int likesCount;
  final bool isLikedByMe;
  final String? username;
  final String? avatarUrl;

  factory Post.fromMap(Map<String, dynamic> map, {required String currentUserId}) {
    final likes = (map['likes'] as List?) ?? [];
    final profile = map['profiles'] as Map<String, dynamic>?;
    return Post(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      imageUrl: map['image_url'] as String,
      caption: map['caption'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      likesCount: likes.length,
      isLikedByMe: likes.any((l) => (l as Map)['user_id'] == currentUserId),
      username: profile?['username'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }

  Post copyWith({
    int? likesCount,
    bool? isLikedByMe,
  }) {
    return Post(
      id: id,
      userId: userId,
      imageUrl: imageUrl,
      caption: caption,
      createdAt: createdAt,
      likesCount: likesCount ?? this.likesCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      username: username,
      avatarUrl: avatarUrl,
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
