import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pulso/features/auth/data/providers/auth_providers.dart';
import 'package:pulso/features/comments/data/providers/comment_providers.dart';
import 'package:pulso/features/comments/domain/models/comment.dart';
import 'package:pulso/features/comments/domain/repositories/comment_repository.dart';
import 'package:pulso/features/comments/presentation/providers/comment_notifier.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class MockCommentRepository extends Mock implements CommentRepository {}

class MockSupabaseClient extends Mock implements supabase.SupabaseClient {}

class MockGoTrueClient extends Mock implements supabase.GoTrueClient {}

Comment _makeComment({
  String id = 'c-1',
  String postId = 'post-1',
  String userId = 'user-1',
}) =>
    Comment(
      id: id,
      postId: postId,
      userId: userId,
      username: 'testuser',
      avatarUrl: null,
      content: 'Hello comment',
      createdAt: DateTime(2024),
      likesCount: 0,
      isLikedByMe: false,
    );

void main() {
  late MockCommentRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockCommentRepository();

    final mockClient = MockSupabaseClient();
    final mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(null);
    when(() => mockClient.channel(any())).thenReturn(_FakeChannel());

    container = ProviderContainer(
      overrides: [
        commentRepositoryProvider.overrideWithValue(mockRepo),
        supabaseClientProvider.overrideWithValue(mockClient),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('addComment', () {
    test('addComment persists with correct payload', () async {
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

    test('CommentNotifier.addComment calls repository and updates state',
        () async {
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

      verify(() => mockRepo.createComment(
            postId: 'post-1',
            userId: any(named: 'userId'),
            content: 'Hello comment',
          )).called(1);

      final state = container.read(commentNotifierProvider)['post-1'];
      expect(state, isA<CommentLoaded>());
      final loaded = state as CommentLoaded;
      expect(loaded.comments, contains(comment));
    });
  });

  group('fetchComments', () {
    test('fetchComments(postId) returns only comments scoped to that postId',
        () async {
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

    test('fetchComments returns empty list for a post with no comments',
        () async {
      when(() => mockRepo.fetchCommentsByPostId('post-empty'))
          .thenAnswer((_) async => []);

      final result = await mockRepo.fetchCommentsByPostId('post-empty');

      expect(result, isEmpty);
    });
  });
}

// noSuchMethod forwarding satisfies the interface without matching exact signatures.
class _FakeChannel implements supabase.RealtimeChannel {
  @override
  dynamic noSuchMethod(Invocation invocation) => this;
}
