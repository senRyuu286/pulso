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
