import 'dart:async';
import 'dart:io';

import 'package:pulso/features/auth/domain/exceptions/auth_exception.dart';
import 'package:pulso/features/auth/domain/models/auth_user.dart';
import 'package:pulso/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this.client);

  final supabase.SupabaseClient client;

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const UnknownAuthException('Unable to create account.');
      }

      await client.from('profiles').insert({
        'id': user.id,
        'username': username,
        'display_name': displayName,
        'created_at': DateTime.now().toIso8601String(),
      });

      return AuthUser(
        id: user.id,
        email: user.email ?? email,
        username: username,
      );
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException();
    } on supabase.AuthException catch (error) {
      throw _mapAuthError(
        error.message,
        statusCode: error.statusCode?.toString(),
      );
    } catch (error) {
      if (error is supabase.PostgrestException) {
        throw _mapAuthError(
          error.message,
          statusCode: error.code,
        );
      }
      throw UnknownAuthException(_messageFromError(error));
    }
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const UnknownAuthException('Unable to sign in.');
      }

      return AuthUser(
        id: user.id,
        email: user.email ?? email,
        username: user.userMetadata?['username'] as String?,
      );
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException();
    } on supabase.AuthException catch (error) {
      throw _mapAuthError(
        error.message,
        statusCode: error.statusCode?.toString(),
      );
    } catch (error) {
      if (error is supabase.PostgrestException) {
        throw _mapAuthError(
          error.message,
          statusCode: error.code,
        );
      }
      throw UnknownAuthException(_messageFromError(error));
    }
  }

  @override
  Future<void> signOut() {
    return client.auth.signOut();
  }

  @override
  Stream<AuthUser?> get authStateChanges {
    return client.auth.onAuthStateChange.map((data) {
      final session = data.session;
      final user = session?.user;
      if (user == null) {
        return null;
      }
      return AuthUser(
        id: user.id,
        email: user.email ?? '',
        username: user.userMetadata?['username'] as String?,
      );
    });
  }

  AuthException _mapAuthError(
    String message, {
    String? statusCode,
  }) {
    final normalizedMessage = message.toLowerCase();
    if (normalizedMessage.contains('invalid credentials') ||
        normalizedMessage.contains('invalid login credentials')) {
      return const InvalidCredentialsException();
    }
    if (normalizedMessage.contains('email address already used') ||
        normalizedMessage.contains('already registered') ||
        statusCode == '422') {
      return const EmailAlreadyInUseException();
    }
    return UnknownAuthException(message);
  }

  String _messageFromError(Object error) {
    final text = error.toString();
    if (text.isEmpty) {
      return 'Something went wrong. Please try again.';
    }
    return text;
  }
}
