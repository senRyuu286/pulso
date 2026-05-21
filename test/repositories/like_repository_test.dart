import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pulso/features/auth/data/providers/auth_providers.dart';
import 'package:pulso/features/likes/data/providers/like_providers.dart';
import 'package:pulso/features/likes/domain/models/like_snapshot.dart';
import 'package:pulso/features/likes/domain/repositories/like_repository.dart';
import 'package:pulso/features/likes/presentation/providers/like_notifier.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class MockLikeRepository extends Mock implements LikeRepository {}

class MockSupabaseClient extends Mock implements supabase.SupabaseClient {}

class MockGoTrueClient extends Mock implements supabase.GoTrueClient {}

void main() {
  late MockLikeRepository mockRepo;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(_FakeRealtimeChannel());
  });

  setUp(() {
    mockRepo = MockLikeRepository();

    final mockClient = MockSupabaseClient();
    final mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(null);
    when(() => mockClient.channel(any())).thenReturn(_FakeRealtimeChannel());
    when(() => mockClient.removeChannel(any())).thenAnswer((_) async => 'ok');

    container = ProviderContainer(
      overrides: [
        likeRepositoryProvider.overrideWithValue(mockRepo),
        supabaseClientProvider.overrideWithValue(mockClient),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('toggleLike', () {
    test('toggleLike inserts when not liked', () async {
      when(() => mockRepo.toggleLike(
            postId: any(named: 'postId'),
            userId: any(named: 'userId'),
            currentlyLiked: false,
          )).thenAnswer((_) async {});

      await mockRepo.toggleLike(
          postId: 'post-1', userId: 'user-1', currentlyLiked: false);

      verify(() => mockRepo.toggleLike(
            postId: 'post-1',
            userId: 'user-1',
            currentlyLiked: false,
          )).called(1);
    });

    test('toggleLike deletes when already liked', () async {
      when(() => mockRepo.toggleLike(
            postId: any(named: 'postId'),
            userId: any(named: 'userId'),
            currentlyLiked: true,
          )).thenAnswer((_) async {});

      await mockRepo.toggleLike(
          postId: 'post-1', userId: 'user-1', currentlyLiked: true);

      verify(() => mockRepo.toggleLike(
            postId: 'post-1',
            userId: 'user-1',
            currentlyLiked: true,
          )).called(1);
    });

    test('LikeNotifier.toggleLike optimistically updates state', () async {
      // Stub fetchLikeSnapshot so the loadLike microtask (scheduled by ensureLoaded)
      // settles into LikeLoaded before toggleLike runs.
      when(() => mockRepo.fetchLikeSnapshot(
            postId: any(named: 'postId'),
            userId: any(named: 'userId'),
          )).thenAnswer(
              (_) async => const LikeSnapshot(count: 5, isLikedByMe: false));
      when(() => mockRepo.toggleLike(
            postId: any(named: 'postId'),
            userId: any(named: 'userId'),
            currentlyLiked: any(named: 'currentlyLiked'),
          )).thenAnswer((_) async {});

      container.read(likeNotifierProvider.notifier).ensureLoaded(
            'post-1',
            seedCount: 5,
            seedIsLiked: false,
          );

      // Drain the microtask queue so loadLike completes before we call toggleLike.
      await Future<void>.delayed(Duration.zero);

      await container.read(likeNotifierProvider.notifier).toggleLike('post-1');

      final state = container.read(likeNotifierProvider)['post-1'];
      expect(state, isA<LikeLoaded>());
      final loaded = state as LikeLoaded;
      expect(loaded.count, 6);
      expect(loaded.isLikedByMe, true);
    });
  });

  group('likeCount', () {
    test('likeCount returns an int', () async {
      when(() => mockRepo.likeCount(any())).thenAnswer((_) async => 42);

      final count = await mockRepo.likeCount('post-1');

      expect(count, isA<int>());
      expect(count, 42);
    });

    test('likeCount returns 0 when no likes', () async {
      when(() => mockRepo.likeCount(any())).thenAnswer((_) async => 0);

      final count = await mockRepo.likeCount('post-empty');

      expect(count, 0);
    });
  });
}

class _FakeRealtimeChannel implements supabase.RealtimeChannel {
  @override
  dynamic noSuchMethod(Invocation invocation) => this;
}
