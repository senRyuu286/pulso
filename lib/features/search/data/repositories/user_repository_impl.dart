import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../domain/models/user_search_result.dart';
import '../../domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this.client);

  final supabase.SupabaseClient client;

  @override
  Future<List<UserSearchResult>> searchUsers(String query) async {
    try {
      final trimmed = query.trim();
      if (trimmed.isEmpty) return [];

      final data = await client
          .from('profiles')
          .select('id, username, avatar_url')
          .ilike('username', '%$trimmed%')
          .order('username')
          .limit(20);

      return (data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(UserSearchResult.fromMap)
          .toList();
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (_) {
      return [];
    }
  }
}
