import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/providers/auth_providers.dart';
import '../../domain/repositories/like_repository.dart';
import '../repositories/like_repository_impl.dart';

final likeRepositoryProvider = Provider<LikeRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return LikeRepositoryImpl(client);
});
