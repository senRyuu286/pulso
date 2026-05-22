import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/data/providers/auth_providers.dart';
import '../../domain/models/post.dart';
import '../../domain/repositories/feed_repository.dart';
import '../repositories/feed_repository_impl.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepositoryImpl(ref.watch(supabaseClientProvider));
});

final repostsByUserProvider = FutureProvider.family<List<Post>, String>(
  (ref, userId) => ref.read(feedRepositoryProvider).fetchRepostsByUser(userId),
);
