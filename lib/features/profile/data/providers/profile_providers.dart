import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/data/providers/auth_providers.dart';
import '../../domain/models/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../repositories/profile_repository_impl.dart';

part 'profile_providers.g.dart';

@riverpod
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepositoryImpl(ref.watch(supabaseClientProvider));
}

@riverpod
Future<Profile> fetchProfile(Ref ref, String userId) {
  return ref.watch(profileRepositoryProvider).fetchProfile(userId);
}

@riverpod
Stream<Profile> watchProfile(Ref ref, String userId) {
  return ref.watch(profileRepositoryProvider).watchProfile(userId);
}
