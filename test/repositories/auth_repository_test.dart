import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pulso/features/auth/data/providers/auth_providers.dart';
import 'package:pulso/features/auth/domain/exceptions/auth_exception.dart';
import 'package:pulso/features/auth/domain/models/auth_user.dart';
import 'package:pulso/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulso/features/auth/presentation/providers/auth_notifier.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late ProviderContainer container;

  const testUser = AuthUser(
    id: 'user-1',
    email: 'test@test.com',
    username: 'testuser',
  );

  setUp(() {
    mockRepo = MockAuthRepository();
    when(() => mockRepo.authStateChanges).thenAnswer(
      (_) => const Stream.empty(),
    );
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('AuthService.signUp', () {
    test('signUp transitions to AuthSuccess on success', () async {
      when(() => mockRepo.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            username: any(named: 'username'),
            displayName: any(named: 'displayName'),
          )).thenAnswer((_) async => testUser);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signUp('test@test.com', 'password', 'testuser', 'Test');

      expect(
        container.read(authNotifierProvider),
        isA<AuthSuccess>().having((s) => s.user, 'user', testUser),
      );
      verify(() => mockRepo.signUp(
            email: 'test@test.com',
            password: 'password',
            username: 'testuser',
            displayName: 'Test',
          )).called(1);
    });

    test('signUp transitions to AuthError on failure', () async {
      when(() => mockRepo.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            username: any(named: 'username'),
            displayName: any(named: 'displayName'),
          )).thenThrow(const EmailAlreadyInUseException());

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signUp('taken@test.com', 'password', 'user', 'User');

      expect(
        container.read(authNotifierProvider),
        isA<AuthError>().having(
          (s) => s.exception,
          'exception',
          isA<EmailAlreadyInUseException>(),
        ),
      );
    });
  });

  group('AuthService.signIn', () {
    test('signIn transitions to AuthSuccess and sets session', () async {
      when(() => mockRepo.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => testUser);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signIn('test@test.com', 'password');

      expect(
        container.read(authNotifierProvider),
        isA<AuthSuccess>().having((s) => s.user.id, 'id', 'user-1'),
      );
      verify(() => mockRepo.signIn(
            email: 'test@test.com',
            password: 'password',
          )).called(1);
    });

    test('signIn transitions to AuthError on invalid credentials', () async {
      when(() => mockRepo.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(const InvalidCredentialsException());

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signIn('test@test.com', 'wrong');

      expect(
        container.read(authNotifierProvider),
        isA<AuthError>().having(
          (s) => s.exception,
          'exception',
          isA<InvalidCredentialsException>(),
        ),
      );
    });
  });

  group('AuthService.signOut', () {
    test('signOut clears session and transitions to AuthInitial', () async {
      // First sign in
      when(() => mockRepo.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => testUser);
      when(() => mockRepo.signOut()).thenAnswer((_) async {});

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signIn('test@test.com', 'password');
      expect(container.read(authNotifierProvider), isA<AuthSuccess>());

      await notifier.signOut();

      expect(
        container.read(authNotifierProvider),
        isA<AuthInitial>(),
      );
      verify(() => mockRepo.signOut()).called(1);
    });
  });
}
