import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pulso/features/auth/data/providers/auth_providers.dart';
import 'package:pulso/features/profile/data/providers/social_providers.dart';
import 'package:pulso/features/profile/domain/repositories/social_repository.dart';
import 'package:pulso/features/profile/presentation/providers/follow_notifier.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class MockSocialRepository extends Mock implements SocialRepository {}

class MockSupabaseClient extends Mock implements supabase.SupabaseClient {}

class MockGoTrueClient extends Mock implements supabase.GoTrueClient {}

void main() {
  late MockSocialRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockSocialRepository();

    final mockClient = MockSupabaseClient();
    final mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(null);
    container = ProviderContainer(
      overrides: [
        socialRepositoryProvider.overrideWithValue(mockRepo),
        supabaseClientProvider.overrideWithValue(mockClient),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('follow', () {
    test('follow inserts a follow record', () async {
      when(() => mockRepo.follow(
            followerId: any(named: 'followerId'),
            followingId: any(named: 'followingId'),
          )).thenAnswer((_) async {});

      await mockRepo.follow(followerId: 'user-1', followingId: 'user-2');

      verify(() => mockRepo.follow(
            followerId: 'user-1',
            followingId: 'user-2',
          )).called(1);
    });

    test('FollowNotifier.toggle calls follow when not following', () async {
      when(() => mockRepo.isFollowing(
            followerId: any(named: 'followerId'),
            followingId: any(named: 'followingId'),
          )).thenAnswer((_) async => false);
      when(() => mockRepo.follow(
            followerId: any(named: 'followerId'),
            followingId: any(named: 'followingId'),
          )).thenAnswer((_) async {});

      final notifier = container.read(followNotifierProvider.notifier);
      await notifier.load('user-2');
      await notifier.toggle('user-2');

      verify(() => mockRepo.follow(
            followerId: any(named: 'followerId'),
            followingId: 'user-2',
          )).called(1);
    });
  });

  group('unfollow', () {
    test('unfollow deletes a follow record', () async {
      when(() => mockRepo.unfollow(
            followerId: any(named: 'followerId'),
            followingId: any(named: 'followingId'),
          )).thenAnswer((_) async {});

      await mockRepo.unfollow(followerId: 'user-1', followingId: 'user-2');

      verify(() => mockRepo.unfollow(
            followerId: 'user-1',
            followingId: 'user-2',
          )).called(1);
    });

    test('FollowNotifier.toggle calls unfollow when already following',
        () async {
      when(() => mockRepo.isFollowing(
            followerId: any(named: 'followerId'),
            followingId: any(named: 'followingId'),
          )).thenAnswer((_) async => true);
      when(() => mockRepo.unfollow(
            followerId: any(named: 'followerId'),
            followingId: any(named: 'followingId'),
          )).thenAnswer((_) async {});

      final notifier = container.read(followNotifierProvider.notifier);
      await notifier.load('user-2');
      await notifier.toggle('user-2');

      verify(() => mockRepo.unfollow(
            followerId: any(named: 'followerId'),
            followingId: 'user-2',
          )).called(1);
    });
  });

  group('isFollowing', () {
    test('isFollowing returns true when following', () async {
      when(() => mockRepo.isFollowing(
            followerId: any(named: 'followerId'),
            followingId: any(named: 'followingId'),
          )).thenAnswer((_) async => true);

      final result = await mockRepo.isFollowing(
          followerId: 'user-1', followingId: 'user-2');

      expect(result, isTrue);
    });

    test('isFollowing returns false when not following', () async {
      when(() => mockRepo.isFollowing(
            followerId: any(named: 'followerId'),
            followingId: any(named: 'followingId'),
          )).thenAnswer((_) async => false);

      final result = await mockRepo.isFollowing(
          followerId: 'user-1', followingId: 'user-3');

      expect(result, isFalse);
    });
  });
}
