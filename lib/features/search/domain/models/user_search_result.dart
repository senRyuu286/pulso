class UserSearchResult {
  const UserSearchResult({
    required this.id,
    required this.username,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String? avatarUrl;

  factory UserSearchResult.fromMap(Map<String, dynamic> map) {
    return UserSearchResult(
      id: map['id'] as String,
      username: map['username'] as String,
      avatarUrl: map['avatar_url'] as String?,
    );
  }
}
