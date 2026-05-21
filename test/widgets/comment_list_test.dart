import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pulso/core/theme/pulso_theme_extension.dart';
import 'package:pulso/features/auth/data/providers/auth_providers.dart';
import 'package:pulso/features/comments/domain/models/comment.dart';
import 'package:pulso/features/comments/presentation/providers/comment_notifier.dart';
import 'package:pulso/features/comments/presentation/widgets/comment_card.dart';
import 'package:pulso/features/feed/domain/models/post.dart';
import 'package:pulso/features/feed/presentation/screens/post_detail_screen.dart';
import 'package:pulso/features/likes/data/providers/like_providers.dart';
import 'package:pulso/features/likes/domain/repositories/like_repository.dart';
import 'package:pulso/features/feed/data/providers/feed_providers.dart';
import 'package:pulso/features/feed/domain/repositories/feed_repository.dart';
import 'package:pulso/features/feed/presentation/providers/repost_notifier.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class MockLikeRepository extends Mock implements LikeRepository {}
class MockFeedRepository extends Mock implements FeedRepository {}
class MockSupabaseClient extends Mock implements supabase.SupabaseClient {}
class MockGoTrueClient extends Mock implements supabase.GoTrueClient {}

Comment _makeComment(String id, String content) => Comment(
      id: id,
      postId: 'post-1',
      userId: 'user-1',
      username: 'testuser',
      avatarUrl: null,
      content: content,
      createdAt: DateTime(2024),
      likesCount: 0,
      isLikedByMe: false,
    );

final _testPost = Post(
  id: 'post-1',
  userId: 'user-1',
  imageUrl: 'https://example.com/img.jpg',
  createdAt: DateTime(2024),
  likesCount: 0,
  isLikedByMe: false,
  repostsCount: 0,
  isRepostedByMe: false,
);

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockLikeRepository mockLikeRepo;
  late MockFeedRepository mockFeedRepo;

  setUpAll(() {
    registerFallbackValue(_FakeChannel());
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockLikeRepo = MockLikeRepository();
    mockFeedRepo = MockFeedRepository();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(null);
    when(() => mockClient.channel(any())).thenReturn(_FakeChannel());
    when(() => mockClient.removeChannel(any())).thenAnswer((_) async => 'ok');
    when(() => mockFeedRepo.fetchPostById(any())).thenAnswer((_) async => _testPost);
  });

  group('CommentList (via CommentsSection)', () {
    testWidgets('renders a list of comments when given data', (tester) async {
      final comments = [
        _makeComment('c-1', 'First comment'),
        _makeComment('c-2', 'Second comment'),
      ];

      await tester.pumpWidget(ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
          likeRepositoryProvider.overrideWithValue(mockLikeRepo),
          feedRepositoryProvider.overrideWithValue(mockFeedRepo),
          commentNotifierProvider
              .overrideWith(() => _PreloadedCommentNotifier(comments)),
          commentCountNotifierProvider
              .overrideWith(() => _FakeCommentCountNotifier()),
          repostNotifierProvider.overrideWith(() => _FakeRepostNotifier()),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: [PulsoThemeExtension.light]),
          home: Scaffold(
            body: CommentsSection(
              post: _testPost,
              commentState: CommentLoaded(comments),
              currentUserId: null,
            ),
          ),
        ),
      ));

      await tester.pump();

      expect(find.byType(CommentCard), findsNWidgets(2));
      expect(find.text('First comment'), findsOneWidget);
      expect(find.text('Second comment'), findsOneWidget);
    });

    testWidgets('shows empty state widget when list is empty', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
          likeRepositoryProvider.overrideWithValue(mockLikeRepo),
          feedRepositoryProvider.overrideWithValue(mockFeedRepo),
          commentNotifierProvider
              .overrideWith(() => _PreloadedCommentNotifier([])),
          commentCountNotifierProvider
              .overrideWith(() => _FakeCommentCountNotifier()),
          repostNotifierProvider.overrideWith(() => _FakeRepostNotifier()),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: [PulsoThemeExtension.light]),
          home: Scaffold(
            body: CommentsSection(
              post: _testPost,
              commentState: const CommentLoaded([]),
              currentUserId: null,
            ),
          ),
        ),
      ));

      await tester.pump();

      expect(find.byType(CommentCard), findsNothing);
      expect(find.text('Be the first to comment.'), findsOneWidget);
    });
  });
}

class _PreloadedCommentNotifier extends CommentNotifier {
  _PreloadedCommentNotifier(this._comments);
  final List<Comment> _comments;

  @override
  CommentMap build() => {'post-1': CommentLoaded(_comments)};
}

class _FakeCommentCountNotifier extends CommentCountNotifier {
  @override
  CommentCountMap build() => {'post-1': 0};
}

class _FakeRepostNotifier extends RepostNotifier {
  @override
  RepostMap build() => {};
}

class _FakeChannel implements supabase.RealtimeChannel {
  @override
  dynamic noSuchMethod(Invocation invocation) => this;
}
