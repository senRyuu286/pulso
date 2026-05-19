import '../models/auth_user.dart';

abstract class AuthRepository {
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  });

  Future<AuthUser> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Stream<AuthUser?> get authStateChanges;
}
