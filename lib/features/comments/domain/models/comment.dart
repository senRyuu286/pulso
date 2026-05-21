/// Comment model for Pulso.
class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.content,
    required this.createdAt,
    required this.likesCount,
    required this.isLikedByMe,
  });

  final String id;
  final String postId;
  final String userId;
  final String? username;
  final String? avatarUrl;
  final String content;
  final DateTime createdAt;
  final int likesCount;
  final bool isLikedByMe;

  factory Comment.fromMap(Map<String, dynamic> map) {
    final profile = map['author'] as Map<String, dynamic>?;
    final createdAtRaw = map['created_at'];
    final createdAt = createdAtRaw is String
        ? DateTime.parse(createdAtRaw)
        : createdAtRaw as DateTime;

    return Comment(
      id: map['id'] as String,
      postId: map['post_id'] as String,
      userId: map['user_id'] as String,
      username: profile?['username'] as String? ?? map['username'] as String?,
      avatarUrl: profile?['avatar_url'] as String? ?? map['avatar_url'] as String?,
      content: map['body'] as String? ?? map['content'] as String? ?? '',
      createdAt: createdAt,
      likesCount: (map['likes_count'] as int?) ?? 0,
      isLikedByMe: (map['is_liked_by_me'] as bool?) ?? false,
    );
  }

  Comment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? username,
    String? avatarUrl,
    String? content,
    DateTime? createdAt,
    int? likesCount,
    bool? isLikedByMe,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }

  @override
  String toString() => 'Comment(id: $id, postId: $postId, userId: $userId, '
      'username: $username, content: $content, createdAt: $createdAt, '
      'likesCount: $likesCount, isLikedByMe: $isLikedByMe)';
}
