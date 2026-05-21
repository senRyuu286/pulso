class AppNotification {
  const AppNotification({
    required this.id,
    required this.recipientId,
    required this.actorId,
    required this.postId,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.actorUsername,
    this.actorAvatarUrl,
    this.postImageUrl,
  });

  final String id;
  final String recipientId;
  final String actorId;
  final String postId;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? actorUsername;
  final String? actorAvatarUrl;
  final String? postImageUrl;

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    final actor = map['actor'] as Map<String, dynamic>?;
    final post = map['post'] as Map<String, dynamic>?;
    return AppNotification(
      id: map['id'] as String,
      recipientId: map['recipient_id'] as String,
      actorId: map['actor_id'] as String,
      postId: map['post_id'] as String,
      type: map['type'] as String? ?? 'new_post',
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      actorUsername: actor?['username'] as String?,
      actorAvatarUrl: actor?['avatar_url'] as String?,
      postImageUrl: post?['image_url'] as String?,
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      recipientId: recipientId,
      actorId: actorId,
      postId: postId,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      actorUsername: actorUsername,
      actorAvatarUrl: actorAvatarUrl,
      postImageUrl: postImageUrl,
    );
  }
}
