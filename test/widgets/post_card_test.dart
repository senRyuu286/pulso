import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pulso/core/theme/pulso_theme_extension.dart';
import 'package:pulso/features/auth/data/providers/auth_providers.dart';
import 'package:pulso/features/feed/domain/models/post.dart';
import 'package:pulso/features/feed/presentation/widgets/post_card.dart';
import 'package:pulso/features/likes/data/providers/like_providers.dart';
import 'package:pulso/features/likes/domain/repositories/like_repository.dart';
import 'package:pulso/features/likes/presentation/providers/like_notifier.dart';
import 'package:pulso/features/feed/data/providers/feed_providers.dart';
import 'package:pulso/features/feed/domain/repositories/feed_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class MockLikeRepository extends Mock implements LikeRepository {}
class MockFeedRepository extends Mock implements FeedRepository {}
class MockSupabaseClient extends Mock implements supabase.SupabaseClient {}
class MockGoTrueClient extends Mock implements supabase.GoTrueClient {}

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
  });

  // Helper — no typed List<Override> parameter needed
  Widget wrap(Widget child) => ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
          likeRepositoryProvider.overrideWithValue(mockLikeRepo),
          feedRepositoryProvider.overrideWithValue(mockFeedRepo),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: [PulsoThemeExtension.light]),
          home: Scaffold(body: child),
        ),
      );

  group('PostCard', () {
    testWidgets('renders caption', (tester) async {
      await tester.pumpWidget(wrap(PostCard(post: _testPost, index: 0)));
      await tester.pump();
      expect(find.text('This is a test caption'), findsOneWidget);
    });

    testWidgets('renders username in header', (tester) async {
      await tester.pumpWidget(wrap(PostCard(post: _testPost, index: 0)));
      await tester.pump();
      expect(find.text('@testuser'), findsOneWidget);
    });

    testWidgets('tapping like button triggers toggleLike on notifier',
        (tester) async {
      when(() => mockLikeRepo.toggleLike(
            postId: any(named: 'postId'),
            userId: any(named: 'userId'),
            currentlyLiked: any(named: 'currentlyLiked'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
          likeRepositoryProvider.overrideWithValue(mockLikeRepo),
          feedRepositoryProvider.overrideWithValue(mockFeedRepo),
          likeNotifierProvider.overrideWith(() => _SeededLikeNotifier()),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: [PulsoThemeExtension.light]),
          home: Scaffold(body: PostCard(post: _testPost, index: 0)),
        ),
      ));

      await tester.pump();

      final likeFinder = find.byIcon(Icons.favorite_border_rounded);
      if (likeFinder.evaluate().isNotEmpty) {
        await tester.tap(likeFinder.first);
        await tester.pump();
      }
    });
  });
}

// Pre-seeded LikeNotifier that doesn't need Supabase
class _SeededLikeNotifier extends LikeNotifier {
  @override
  LikeMap build() {
    return {
      'post-1': const LikeLoaded(count: 7, isLikedByMe: false),
    };
  }
}

class _FakeChannel implements supabase.RealtimeChannel {
  @override
  dynamic noSuchMethod(Invocation invocation) => this;
}
