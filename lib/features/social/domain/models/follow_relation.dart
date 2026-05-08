class FollowRelation {
  const FollowRelation({
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  final String followerId;
  final String followingId;
  final DateTime createdAt;

  factory FollowRelation.fromMap(Map<String, dynamic> map) {
    return FollowRelation(
      followerId: map['follower_id'] as String,
      followingId: map['following_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FollowRelation &&
        other.followerId == followerId &&
        other.followingId == followingId;
  }

  @override
  int get hashCode => Object.hash(followerId, followingId);
}
