import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/providers/auth_providers.dart';
import '../../domain/repositories/social_repository.dart';
import '../repositories/social_repository_impl.dart';

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepositoryImpl(ref.watch(supabaseClientProvider));
});
