class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.username,
  });

  final String id;
  final String email;
  final String? username;

  AuthUser copyWith({
    String? id,
    String? email,
    String? username,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AuthUser &&
        other.id == id &&
        other.email == email &&
        other.username == username;
  }

  @override
  int get hashCode => Object.hash(id, email, username);
}