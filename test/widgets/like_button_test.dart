import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pulso/features/auth/data/providers/auth_providers.dart';
import 'package:pulso/features/feed/domain/models/post.dart';
import 'package:pulso/features/feed/presentation/widgets/like_button.dart';
import 'package:pulso/features/likes/data/providers/like_providers.dart';
import 'package:pulso/features/likes/domain/repositories/like_repository.dart';
import 'package:pulso/features/likes/presentation/providers/like_notifier.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class MockLikeRepository extends Mock implements LikeRepository {}
class MockSupabaseClient extends Mock implements supabase.SupabaseClient {}
class MockGoTrueClient extends Mock implements supabase.GoTrueClient {}

Post _makePost({bool isLikedByMe = false, int likesCount = 0}) => Post(
      id: 'post-1',
      userId: 'user-1',
      imageUrl: 'https://example.com/img.jpg',
      createdAt: DateTime(2024),
      likesCount: likesCount,
      isLikedByMe: isLikedByMe,
      repostsCount: 0,
      isRepostedByMe: false,
    );

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockLikeRepository mockLikeRepo;

  setUpAll(() {
    registerFallbackValue(_FakeChannel());
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockLikeRepo = MockLikeRepository();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(null);
    when(() => mockClient.channel(any())).thenReturn(_FakeChannel());
    when(() => mockClient.removeChannel(any())).thenAnswer((_) async => 'ok');
  });

  group('LikeButton', () {
    testWidgets('shows filled heart icon when isLiked == true', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
          likeRepositoryProvider.overrideWithValue(mockLikeRepo),
          likeNotifierProvider
              .overrideWith(() => _SeededLikeNotifier(isLiked: true)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: LikeButton(post: _makePost(isLikedByMe: true, likesCount: 5)),
          ),
        ),
      ));

      await tester.pump();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    });

    testWidgets('shows unfilled heart icon when isLiked == false',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
          likeRepositoryProvider.overrideWithValue(mockLikeRepo),
          likeNotifierProvider
              .overrideWith(() => _SeededLikeNotifier(isLiked: false)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: LikeButton(post: _makePost(isLikedByMe: false, likesCount: 3)),
          ),
        ),
      ));

      await tester.pump();

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets('onTap calls toggleLike on the notifier', (tester) async {
      bool toggleCalled = false;

      await tester.pumpWidget(ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
          likeRepositoryProvider.overrideWithValue(mockLikeRepo),
          likeNotifierProvider.overrideWith(
              () => _TrackingLikeNotifier(onToggle: () => toggleCalled = true)),
        ],
        child: MaterialApp(
          home: Scaffold(body: LikeButton(post: _makePost())),
        ),
      ));

      await tester.pump();

      await tester.tap(find.byType(LikeButton));
      await tester.pumpAndSettle();

      expect(toggleCalled, isTrue);
    });
  });
}

class _SeededLikeNotifier extends LikeNotifier {
  _SeededLikeNotifier({required this.isLiked});
  final bool isLiked;

  @override
  LikeMap build() => {
        'post-1': LikeLoaded(count: isLiked ? 5 : 3, isLikedByMe: isLiked),
      };

  @override
  void ensureLoaded(String postId, {int? seedCount, bool? seedIsLiked}) {}
}

class _TrackingLikeNotifier extends LikeNotifier {
  _TrackingLikeNotifier({required this.onToggle});
  final VoidCallback onToggle;

  @override
  LikeMap build() => {
        'post-1': const LikeLoaded(count: 0, isLikedByMe: false),
      };

  @override
  void ensureLoaded(String postId, {int? seedCount, bool? seedIsLiked}) {}

  @override
  Future<void> toggleLike(String postId) async {
    onToggle();
  }
}

class _FakeChannel implements supabase.RealtimeChannel {
  @override
  dynamic noSuchMethod(Invocation invocation) => this;
}
