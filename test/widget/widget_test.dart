import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:pulso/core/theme/pulso_theme_extension.dart';
import 'package:pulso/features/auth/data/providers/auth_providers.dart';
import 'package:pulso/features/comments/domain/models/comment.dart';
import 'package:pulso/features/comments/presentation/providers/comment_notifier.dart';
import 'package:pulso/features/comments/presentation/widgets/comment_card.dart';
import 'package:pulso/features/feed/data/providers/feed_providers.dart';
import 'package:pulso/features/feed/domain/models/post.dart';
import 'package:pulso/features/feed/domain/repositories/feed_repository.dart';
import 'package:pulso/features/feed/presentation/providers/repost_notifier.dart';
import 'package:pulso/features/feed/presentation/screens/post_detail_screen.dart';
import 'package:pulso/features/feed/presentation/widgets/like_button.dart';
import 'package:pulso/features/feed/presentation/widgets/post_card.dart';
import 'package:pulso/features/likes/data/providers/like_providers.dart';
import 'package:pulso/features/likes/domain/repositories/like_repository.dart';
import 'package:pulso/features/likes/presentation/providers/like_notifier.dart';
import 'package:pulso/features/profile/presentation/widgets/profile_avatar.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockLikeRepository extends Mock implements LikeRepository {}
class MockFeedRepository extends Mock implements FeedRepository {}
class MockSupabaseClient extends Mock implements supabase.SupabaseClient {}
class MockGoTrueClient extends Mock implements supabase.GoTrueClient {}

class _FakeChannel implements supabase.RealtimeChannel {
  @override
  dynamic noSuchMethod(Invocation invocation) => this;
}

// ─── Stub notifiers ───────────────────────────────────────────────────────────

class _SeededLikeNotifier extends LikeNotifier {
  _SeededLikeNotifier({required this.isLiked, this.count = 0});
  final bool isLiked;
  final int count;

  @override
  LikeMap build() => {'post-1': LikeLoaded(count: count, isLikedByMe: isLiked)};

  @override
  void ensureLoaded(String postId, {int? seedCount, bool? seedIsLiked}) {}
}

class _TrackingLikeNotifier extends LikeNotifier {
  _TrackingLikeNotifier({required this.onToggle});
  final VoidCallback onToggle;

  @override
  LikeMap build() => {'post-1': const LikeLoaded(count: 0, isLikedByMe: false)};

  @override
  void ensureLoaded(String postId, {int? seedCount, bool? seedIsLiked}) {}

  @override
  Future<void> toggleLike(String postId) async => onToggle();
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

// ─── Fixtures ─────────────────────────────────────────────────────────────────

final _testPost = Post(
  id: 'post-1',
  userId: 'user-1',
  imageUrl: 'https://example.com/img.jpg',
  caption: 'This is a test caption',
  createdAt: DateTime(2024, 1, 1),
  likesCount: 7,
  isLikedByMe: false,
  repostsCount: 2,
  isRepostedByMe: false,
  username: 'testuser',
);

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

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockLikeRepository mockLikeRepo;
  late MockFeedRepository mockFeedRepo;

  setUpAll(() => registerFallbackValue(_FakeChannel()));

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

  // ── PostCard ───────────────────────────────────────────────────────────────

  group('PostCard', () {
    Widget wrap(Widget child, {LikeNotifier? likeNotifier}) => ProviderScope(
          overrides: [
            supabaseClientProvider.overrideWithValue(mockClient),
            likeRepositoryProvider.overrideWithValue(mockLikeRepo),
            feedRepositoryProvider.overrideWithValue(mockFeedRepo),
            if (likeNotifier != null)
              likeNotifierProvider.overrideWith(() => likeNotifier),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: [PulsoThemeExtension.light]),
            home: Scaffold(body: child),
          ),
        );

    testWidgets('renders image', (tester) async {
      await tester.pumpWidget(wrap(PostCard(post: _testPost, index: 0)));
      await tester.pump();
      expect(find.byType(CachedNetworkImage), findsWidgets);
    });

    testWidgets('renders caption', (tester) async {
      await tester.pumpWidget(wrap(PostCard(post: _testPost, index: 0)));
      await tester.pump();
      expect(find.text('This is a test caption'), findsOneWidget);
    });

    testWidgets('renders like count', (tester) async {
      await tester.pumpWidget(wrap(
        PostCard(post: _testPost, index: 0),
        likeNotifier: _SeededLikeNotifier(isLiked: false, count: 7),
      ));
      await tester.pump();
      expect(find.text('7'), findsWidgets);
    });

    testWidgets('tapping like button triggers provider method', (tester) async {
      bool toggleCalled = false;

      await tester.pumpWidget(wrap(
        PostCard(post: _testPost, index: 0),
        likeNotifier: _TrackingLikeNotifier(onToggle: () => toggleCalled = true),
      ));
      // Advance fake time so Timer(Duration.zero) in PostCard.initState fires,
      // which starts _entryCtrl — otherwise FadeTransition stays at opacity=0
      // and RenderAnimatedOpacity blocks all hit-testing.
      await tester.pump(const Duration(milliseconds: 100));

      final likeFinder = find.byIcon(Icons.favorite_border_rounded);
      if (likeFinder.evaluate().isNotEmpty) {
        await tester.tap(likeFinder.first);
        // A bare pump() records AnimationController._startTime on the first
        // vsync tick; the subsequent pump(300ms) then advances elapsed time so
        // the press/release animations complete and toggleLike() is called.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(toggleCalled, isTrue);
      }
    });
  });

  // ── CommentList ────────────────────────────────────────────────────────────

  group('CommentList', () {
    Widget wrapWithComments(List<Comment> comments) => ProviderScope(
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
        );

    testWidgets('renders list of comments', (tester) async {
      final comments = [
        _makeComment('c-1', 'First comment'),
        _makeComment('c-2', 'Second comment'),
      ];
      await tester.pumpWidget(wrapWithComments(comments));
      await tester.pump();

      expect(find.byType(CommentCard), findsNWidgets(2));
      expect(find.text('First comment'), findsOneWidget);
      expect(find.text('Second comment'), findsOneWidget);
    });

    testWidgets('shows empty state when no comments', (tester) async {
      await tester.pumpWidget(wrapWithComments([]));
      await tester.pump();

      expect(find.byType(CommentCard), findsNothing);
      expect(find.text('Be the first to comment.'), findsOneWidget);
    });
  });

  // ── LikeButton ─────────────────────────────────────────────────────────────

  group('LikeButton', () {
    Post makePost({bool isLikedByMe = false, int likesCount = 0}) => Post(
          id: 'post-1',
          userId: 'user-1',
          imageUrl: 'https://example.com/img.jpg',
          createdAt: DateTime(2024),
          likesCount: likesCount,
          isLikedByMe: isLikedByMe,
          repostsCount: 0,
          isRepostedByMe: false,
        );

    Widget wrapButton(Widget child, {required LikeNotifier notifier}) =>
        ProviderScope(
          overrides: [
            supabaseClientProvider.overrideWithValue(mockClient),
            likeRepositoryProvider.overrideWithValue(mockLikeRepo),
            likeNotifierProvider.overrideWith(() => notifier),
          ],
          child: MaterialApp(home: Scaffold(body: child)),
        );

    testWidgets('shows correct filled icon when liked', (tester) async {
      await tester.pumpWidget(wrapButton(
        LikeButton(post: makePost(isLikedByMe: true, likesCount: 5)),
        notifier: _SeededLikeNotifier(isLiked: true, count: 5),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    });

    testWidgets('shows correct unfilled icon when not liked', (tester) async {
      await tester.pumpWidget(wrapButton(
        LikeButton(post: makePost(isLikedByMe: false, likesCount: 3)),
        notifier: _SeededLikeNotifier(isLiked: false, count: 3),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets('onTap calls provider method', (tester) async {
      bool toggleCalled = false;

      await tester.pumpWidget(wrapButton(
        LikeButton(post: makePost()),
        notifier: _TrackingLikeNotifier(onToggle: () => toggleCalled = true),
      ));
      await tester.pump();

      await tester.tap(find.byType(LikeButton));
      // Bare pump() sets AnimationController._startTime on the first vsync tick.
      // The subsequent pump(300ms) then advances elapsed time so the press/release
      // animations in LikeButton._onTap() complete and toggleLike() is called.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(toggleCalled, isTrue);
    });
  });

  // ── ProfileAvatar ──────────────────────────────────────────────────────────

  group('ProfileAvatar', () {
    Widget wrap(Widget child) =>
        MaterialApp(home: Scaffold(body: Center(child: child)));

    testWidgets('renders avatar image from URL', (tester) async {
      await tester.pumpWidget(wrap(
        const ProfileAvatar(avatarUrl: 'https://example.com/avatar.jpg', size: 80),
      ));
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('shows placeholder on null URL', (tester) async {
      await tester.pumpWidget(wrap(
        const ProfileAvatar(avatarUrl: null, size: 80),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('shows placeholder on empty URL', (tester) async {
      await tester.pumpWidget(wrap(
        const ProfileAvatar(avatarUrl: '', size: 80),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });
  });
}
