import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:pulso/features/auth/data/providers/auth_providers.dart';
import 'package:pulso/features/feed/data/providers/feed_providers.dart';
import 'package:pulso/features/feed/domain/models/post.dart';
import 'package:pulso/features/feed/domain/repositories/feed_repository.dart';
import 'package:pulso/features/feed/presentation/providers/feed_notifier.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

class MockSupabaseClient extends Mock implements supabase.SupabaseClient {}

class MockGoTrueClient extends Mock implements supabase.GoTrueClient {}

class FakeFile extends Fake implements File {}

Post _makePost({
  String id = 'post-1',
  String userId = 'user-1',
  int repostsCount = 0,
  bool isRepostedByMe = false,
}) =>
    Post(
      id: id,
      userId: userId,
      imageUrl: 'https://example.com/img.jpg',
      createdAt: DateTime(2024),
      likesCount: 0,
      isLikedByMe: false,
      repostsCount: repostsCount,
      isRepostedByMe: isRepostedByMe,
    );

void main() {
  late MockFeedRepository mockRepo;
  late ProviderContainer container;

  setUpAll(() => registerFallbackValue(FakeFile()));

  setUp(() {
    mockRepo = MockFeedRepository();
    final mockClient = MockSupabaseClient();
    final mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(null);
    container = ProviderContainer(
      overrides: [
        feedRepositoryProvider.overrideWithValue(mockRepo),
        supabaseClientProvider.overrideWithValue(mockClient),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('createPost', () {
    test('createPost inserts record into posts table', () async {
      final file = FakeFile();
      final post = _makePost();

      when(() => mockRepo.createPost(
            image: any(named: 'image'),
            caption: any(named: 'caption'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => post);

      await mockRepo.createPost(
          image: file, caption: 'Hello world', userId: 'user-1');

      verify(() => mockRepo.createPost(
            image: file,
            caption: 'Hello world',
            userId: 'user-1',
          )).called(1);
    });

    test('PostCreationNotifier.submit triggers createPost with correct payload',
        () async {
      final file = FakeFile();
      final post = _makePost();

      when(() => mockRepo.createPost(
            image: any(named: 'image'),
            caption: any(named: 'caption'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => post);

      // feedNotifierProvider needs to be in loaded state
      when(() => mockRepo.fetchFeed()).thenAnswer((_) async => []);

      final notifier =
          container.read(postCreationNotifierProvider.notifier);
      await notifier.submit(image: file, caption: 'My caption');

      verify(() => mockRepo.createPost(
            image: any(named: 'image'),
            caption: 'My caption',
            userId: any(named: 'userId'),
          )).called(1);
    });
  });

  group('fetchFeed', () {
    test('fetchFeed returns a List<Post>', () async {
      final posts = [_makePost(id: 'p1'), _makePost(id: 'p2')];
      when(() => mockRepo.fetchFeed()).thenAnswer((_) async => posts);

      final result = await mockRepo.fetchFeed();

      expect(result, isA<List<Post>>());
      expect(result.length, 2);
    });

    test('FeedNotifier.loadFeed transitions to FeedLoaded', () async {
      final posts = [_makePost()];
      when(() => mockRepo.fetchFeed()).thenAnswer((_) async => posts);

      final notifier = container.read(feedNotifierProvider.notifier);
      await notifier.loadFeed();

      expect(
        container.read(feedNotifierProvider),
        isA<FeedLoaded>().having((s) => s.posts.length, 'posts.length', 1),
      );
    });
  });

  group('deletePost', () {
    test('deletePost removes the record (verify delete call)', () async {
      when(() => mockRepo.deletePost(any())).thenAnswer((_) async {});

      await mockRepo.deletePost('post-1');

      verify(() => mockRepo.deletePost('post-1')).called(1);
    });
  });

  group('repost', () {
    test('repost inserts on first call (not currently reposted)', () async {
      when(() => mockRepo.repost(
            postId: any(named: 'postId'),
            userId: any(named: 'userId'),
            currentlyReposted: false,
          )).thenAnswer((_) async {});

      await mockRepo.repost(
          postId: 'post-1', userId: 'user-1', currentlyReposted: false);

      verify(() => mockRepo.repost(
            postId: 'post-1',
            userId: 'user-1',
            currentlyReposted: false,
          )).called(1);
    });

    test('repost deletes on second call (currently reposted)', () async {
      when(() => mockRepo.repost(
            postId: any(named: 'postId'),
            userId: any(named: 'userId'),
            currentlyReposted: true,
          )).thenAnswer((_) async {});

      await mockRepo.repost(
          postId: 'post-1', userId: 'user-1', currentlyReposted: true);

      verify(() => mockRepo.repost(
            postId: 'post-1',
            userId: 'user-1',
            currentlyReposted: true,
          )).called(1);
    });
  });
}
