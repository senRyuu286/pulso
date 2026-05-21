import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/comment_repository.dart';
import '../repositories/comment_repository_impl.dart';

/// Provider for the comment repository.
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepositoryImpl();
});
