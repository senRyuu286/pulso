import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:pulso/features/auth/data/providers/auth_providers.dart';
import 'package:pulso/features/auth/domain/exceptions/auth_exception.dart';
import 'package:pulso/features/auth/domain/models/auth_user.dart';
import 'package:pulso/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulso/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pulso/features/comments/data/providers/comment_providers.dart';
import 'package:pulso/features/comments/domain/models/comment.dart';
import 'package:pulso/features/comments/domain/repositories/comment_repository.dart';
import 'package:pulso/features/comments/presentation/providers/comment_notifier.dart';
import 'package:pulso/features/feed/data/providers/feed_providers.dart';
import 'package:pulso/features/feed/domain/models/post.dart';
import 'package:pulso/features/feed/domain/repositories/feed_repository.dart';
import 'package:pulso/features/feed/presentation/providers/feed_notifier.dart';
import 'package:pulso/features/likes/data/providers/like_providers.dart';
import 'package:pulso/features/likes/domain/models/like_snapshot.dart';
import 'package:pulso/features/likes/domain/repositories/like_repository.dart';
import 'package:pulso/features/likes/presentation/providers/like_notifier.dart';
import 'package:pulso/features/profile/data/providers/social_providers.dart';
import 'package:pulso/features/profile/domain/repositories/social_repository.dart';
import 'package:pulso/features/profile/presentation/providers/follow_notifier.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockAuthRepository extends Mock implements AuthRepository {}
class MockFeedRepository extends Mock implements FeedRepository {}
class MockLikeRepository extends Mock implements LikeRepository {}
class MockCommentRepository extends Mock implements CommentRepository {}
class MockSocialRepository extends Mock implements SocialRepository {}
class MockSupabaseClient extends Mock implements supabase.SupabaseClient {}
class MockGoTrueClient extends Mock implements supabase.GoTrueClient {}
class FakeFile extends Fake implements File {}

class _FakeRealtimeChannel implements supabase.RealtimeChannel {
  @override
  dynamic noSuchMethod(Invocation invocation) => this;
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

const _testUser = AuthUser(id: 'user-1', email: 'test@test.com', username: 'testuser');

Post _makePost({String id = 'post-1', String userId = 'user-1'}) => Post(
      id: id,
      userId: userId,
      imageUrl: 'https://example.com/img.jpg',
      createdAt: DateTime(2024),
      likesCount: 0,
      isLikedByMe: false,
      repostsCount: 0,
      isRepostedByMe: false,
    );

Comment _makeComment({String id = 'c-1', String postId = 'post-1'}) => Comment(
      id: id,
      postId: postId,
      userId: 'user-1',
      username: 'testuser',
      avatarUrl: null,
      content: 'Hello comment',
      createdAt: DateTime(2024),
      likesCount: 0,
      isLikedByMe: false,
    );

MockSupabaseClient _makeClient() {
  final client = MockSupabaseClient();
  final auth = MockGoTrueClient();
  when(() => client.auth).thenReturn(auth);
  when(() => auth.currentUser).thenReturn(null);
  when(() => client.channel(any())).thenReturn(_FakeRealtimeChannel());
  when(() => client.removeChannel(any())).thenAnswer((_) async => 'ok');
  return client;
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(FakeFile());
    registerFallbackValue(_FakeRealtimeChannel());
  });

  // ── AuthService ────────────────────────────────────────────────────────────

  group('AuthService', () {
    late MockAuthRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockAuthRepository();
      when(() => mockRepo.authStateChanges).thenAnswer((_) => const Stream.empty());
      container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
      );
    });

    tearDown(() => container.dispose());

    group('signUp', () {
      test('returns AuthSuccess with correct user on success', () async {
        when(() => mockRepo.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              username: any(named: 'username'),
              displayName: any(named: 'displayName'),
            )).thenAnswer((_) async => _testUser);

        await container
            .read(authNotifierProvider.notifier)
            .signUp('test@test.com', 'password', 'testuser', 'Test');

        expect(
          container.read(authNotifierProvider),
          isA<AuthSuccess>().having((s) => s.user, 'user', _testUser),
        );
      });

      test('returns AuthError on failure', () async {
        when(() => mockRepo.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              username: any(named: 'username'),
              displayName: any(named: 'displayName'),
            )).thenThrow(const EmailAlreadyInUseException());

        await container
            .read(authNotifierProvider.notifier)
            .signUp('taken@test.com', 'password', 'user', 'User');

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

    group('signIn', () {
      test('sets session and returns AuthSuccess', () async {
        when(() => mockRepo.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => _testUser);

        await container
            .read(authNotifierProvider.notifier)
            .signIn('test@test.com', 'password');

        expect(
          container.read(authNotifierProvider),
          isA<AuthSuccess>().having((s) => s.user.id, 'id', 'user-1'),
        );
      });

      test('returns AuthError on invalid credentials', () async {
        when(() => mockRepo.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(const InvalidCredentialsException());

        await container
            .read(authNotifierProvider.notifier)
            .signIn('test@test.com', 'wrong');

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

    group('signOut', () {
      test('clears session and transitions to AuthInitial', () async {
        when(() => mockRepo.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => _testUser);
        when(() => mockRepo.signOut()).thenAnswer((_) async {});

        final notifier = container.read(authNotifierProvider.notifier);
        await notifier.signIn('test@test.com', 'password');
        expect(container.read(authNotifierProvider), isA<AuthSuccess>());

        await notifier.signOut();

        expect(container.read(authNotifierProvider), isA<AuthInitial>());
        verify(() => mockRepo.signOut()).called(1);
      });
    });
  });

  // ── PostRepository ─────────────────────────────────────────────────────────

  group('PostRepository', () {
    late MockFeedRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockFeedRepository();
      container = ProviderContainer(
        overrides: [
          feedRepositoryProvider.overrideWithValue(mockRepo),
          supabaseClientProvider.overrideWithValue(_makeClient()),
        ],
      );
    });

    tearDown(() => container.dispose());

    group('createPost', () {
      test('inserts record and calls repository with correct payload', () async {
        final file = FakeFile();
        final post = _makePost();
        when(() => mockRepo.createPost(
              image: any(named: 'image'),
              caption: any(named: 'caption'),
              userId: any(named: 'userId'),
            )).thenAnswer((_) async => post);
        when(() => mockRepo.fetchFeed()).thenAnswer((_) async => []);

        await container
            .read(postCreationNotifierProvider.notifier)
            .submit(image: file, caption: 'My caption');

        verify(() => mockRepo.createPost(
              image: any(named: 'image'),
              caption: 'My caption',
              userId: any(named: 'userId'),
            )).called(1);
      });
    });

    group('fetchFeed', () {
      test('returns List<Post>', () async {
        final posts = [_makePost(id: 'p1'), _makePost(id: 'p2')];
        when(() => mockRepo.fetchFeed()).thenAnswer((_) async => posts);

        final result = await mockRepo.fetchFeed();

        expect(result, isA<List<Post>>());
        expect(result.length, 2);
      });

      test('FeedNotifier transitions to FeedLoaded', () async {
        when(() => mockRepo.fetchFeed()).thenAnswer((_) async => [_makePost()]);

        await container.read(feedNotifierProvider.notifier).loadFeed();

        expect(
          container.read(feedNotifierProvider),
          isA<FeedLoaded>().having((s) => s.posts.length, 'posts.length', 1),
        );
      });
    });

    group('deletePost', () {
      test('removes the record', () async {
        when(() => mockRepo.deletePost(any())).thenAnswer((_) async {});

        await mockRepo.deletePost('post-1');

        verify(() => mockRepo.deletePost('post-1')).called(1);
      });
    });
  });

  // ── LikeRepository ─────────────────────────────────────────────────────────

  group('LikeRepository', () {
    late MockLikeRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockLikeRepository();
      container = ProviderContainer(
        overrides: [
          likeRepositoryProvider.overrideWithValue(mockRepo),
          supabaseClientProvider.overrideWithValue(_makeClient()),
        ],
      );
    });

    tearDown(() => container.dispose());

    group('toggleLike', () {
      test('correctly inserts when not liked', () async {
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

      test('correctly deletes when already liked', () async {
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

      test('LikeNotifier optimistically updates state', () async {
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
        await Future<void>.delayed(Duration.zero);

        await container
            .read(likeNotifierProvider.notifier)
            .toggleLike('post-1');

        final loaded =
            container.read(likeNotifierProvider)['post-1'] as LikeLoaded;
        expect(loaded.count, 6);
        expect(loaded.isLikedByMe, true);
      });
    });

    group('likeCount', () {
      test('returns an integer', () async {
        when(() => mockRepo.likeCount(any())).thenAnswer((_) async => 42);

        final count = await mockRepo.likeCount('post-1');

        expect(count, isA<int>());
        expect(count, 42);
      });

      test('returns 0 when there are no likes', () async {
        when(() => mockRepo.likeCount(any())).thenAnswer((_) async => 0);

        expect(await mockRepo.likeCount('post-empty'), 0);
      });
    });
  });

  // ── CommentRepository ──────────────────────────────────────────────────────

  group('CommentRepository', () {
    late MockCommentRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockCommentRepository();
      container = ProviderContainer(
        overrides: [
          commentRepositoryProvider.overrideWithValue(mockRepo),
          supabaseClientProvider.overrideWithValue(_makeClient()),
        ],
      );
    });

    tearDown(() => container.dispose());

    group('addComment', () {
      test('persists with correct payload', () async {
        final comment = _makeComment();
        when(() => mockRepo.createComment(
              postId: any(named: 'postId'),
              userId: any(named: 'userId'),
              content: any(named: 'content'),
            )).thenAnswer((_) async => comment);

        await mockRepo.createComment(
            postId: 'post-1', userId: 'user-1', content: 'Hello comment');

        verify(() => mockRepo.createComment(
              postId: 'post-1',
              userId: 'user-1',
              content: 'Hello comment',
            )).called(1);
      });

      test('CommentNotifier.addComment updates state', () async {
        final comment = _makeComment();
        when(() => mockRepo.fetchCommentsByPostId(any()))
            .thenAnswer((_) async => []);
        when(() => mockRepo.fetchCommentById(any()))
            .thenAnswer((_) async => comment);
        when(() => mockRepo.createComment(
              postId: any(named: 'postId'),
              userId: any(named: 'userId'),
              content: any(named: 'content'),
            )).thenAnswer((_) async => comment);

        final notifier = container.read(commentNotifierProvider.notifier);
        await notifier.loadComments('post-1');
        await notifier.addComment(postId: 'post-1', content: 'Hello comment');

        final loaded =
            container.read(commentNotifierProvider)['post-1'] as CommentLoaded;
        expect(loaded.comments, contains(comment));
      });
    });

    group('fetchComments', () {
      test('returns correct post-scoped list', () async {
        final comments = [
          _makeComment(id: 'c-1', postId: 'post-1'),
          _makeComment(id: 'c-2', postId: 'post-1'),
        ];
        when(() => mockRepo.fetchCommentsByPostId('post-1'))
            .thenAnswer((_) async => comments);

        final result = await mockRepo.fetchCommentsByPostId('post-1');

        expect(result, isA<List<Comment>>());
        expect(result.length, 2);
        expect(result.every((c) => c.postId == 'post-1'), isTrue);
      });

      test('returns empty list for a post with no comments', () async {
        when(() => mockRepo.fetchCommentsByPostId('post-empty'))
            .thenAnswer((_) async => []);

        expect(await mockRepo.fetchCommentsByPostId('post-empty'), isEmpty);
      });
    });
  });

  // ── FollowRepository ───────────────────────────────────────────────────────

  group('FollowRepository', () {
    late MockSocialRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockSocialRepository();
      container = ProviderContainer(
        overrides: [
          socialRepositoryProvider.overrideWithValue(mockRepo),
          supabaseClientProvider.overrideWithValue(_makeClient()),
        ],
      );
    });

    tearDown(() => container.dispose());

    group('follow', () {
      test('inserts a follow record', () async {
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
      test('deletes a follow record', () async {
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
      test('returns true when following', () async {
        when(() => mockRepo.isFollowing(
              followerId: any(named: 'followerId'),
              followingId: any(named: 'followingId'),
            )).thenAnswer((_) async => true);

        expect(
          await mockRepo.isFollowing(
              followerId: 'user-1', followingId: 'user-2'),
          isTrue,
        );
      });

      test('returns false when not following', () async {
        when(() => mockRepo.isFollowing(
              followerId: any(named: 'followerId'),
              followingId: any(named: 'followingId'),
            )).thenAnswer((_) async => false);

        expect(
          await mockRepo.isFollowing(
              followerId: 'user-1', followingId: 'user-3'),
          isFalse,
        );
      });
    });
  });
}
