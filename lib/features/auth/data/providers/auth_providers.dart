import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../repositories/auth_repository_impl.dart';

final supabaseClientProvider = Provider<supabase.SupabaseClient>((ref) {
  return supabase.Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(supabaseClientProvider));
});

final authStateChangesProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
