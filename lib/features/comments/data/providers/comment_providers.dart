import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/providers/auth_providers.dart';
import '../../domain/repositories/comment_repository.dart';
import '../repositories/comment_repository_impl.dart';

/// Provider for the comment repository.
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CommentRepositoryImpl(client);
});
