import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/auth_providers.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthSuccess extends AuthState {
  const AuthSuccess(this.user);

  final AuthUser user;
}

final class AuthError extends AuthState {
  const AuthError(this.exception);

  final AuthException exception;
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthInitial();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> signUp(
    String email,
    String password,
    String username,
    String displayName,
  ) async {
    state = const AuthLoading();
    try {
      final user = await _repository.signUp(
        email: email,
        password: password,
        username: username,
        displayName: displayName,
      );
      state = AuthSuccess(user);
    } on AuthException catch (exception) {
      state = AuthError(exception);
    } catch (error) {
      state = AuthError(UnknownAuthException(error.toString()));
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AuthLoading();
    try {
      final user = await _repository.signIn(
        email: email,
        password: password,
      );
      state = AuthSuccess(user);
    } on AuthException catch (exception) {
      state = AuthError(exception);
    } catch (error) {
      state = AuthError(UnknownAuthException(error.toString()));
    }
  }

  Future<void> signOut() async {
    state = const AuthLoading();
    try {
      await _repository.signOut();
      state = const AuthInitial();
    } on AuthException catch (exception) {
      state = AuthError(exception);
    } catch (error) {
      state = AuthError(UnknownAuthException(error.toString()));
    }
  }
}
