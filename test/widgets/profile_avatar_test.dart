import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulso/features/profile/presentation/widgets/profile_avatar.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('ProfileAvatar', () {
    testWidgets('renders CachedNetworkImage when given a URL', (tester) async {
      await tester.pumpWidget(_wrap(
        const ProfileAvatar(
          avatarUrl: 'https://example.com/avatar.jpg',
          size: 80,
        ),
      ));

      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('shows placeholder widget when URL is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const ProfileAvatar(
          avatarUrl: null,
          size: 80,
        ),
      ));

      await tester.pump();

      // When URL is null/empty, CachedNetworkImage falls back to errorWidget
      // which renders _GradientPlaceholder containing a person icon
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('shows placeholder widget when URL is empty string',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const ProfileAvatar(
          avatarUrl: '',
          size: 80,
        ),
      ));

      await tester.pump();

      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('renders edit button when showEditButton is true',
        (tester) async {
      await tester.pumpWidget(_wrap(
        ProfileAvatar(
          avatarUrl: null,
          size: 80,
          showEditButton: true,
          onEditTap: () {},
        ),
      ));

      await tester.pump();

      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
    });

    testWidgets('does not render edit button when showEditButton is false',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const ProfileAvatar(
          avatarUrl: null,
          size: 80,
          showEditButton: false,
        ),
      ));

      await tester.pump();

      expect(find.byIcon(Icons.camera_alt_rounded), findsNothing);
    });
  });
}
