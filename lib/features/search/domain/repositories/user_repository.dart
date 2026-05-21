import '../models/user_search_result.dart';

abstract class UserRepository {
  Future<List<UserSearchResult>> searchUsers(String query);
}
