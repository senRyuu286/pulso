import 'dart:io';
import '../models/post.dart';

abstract class FeedRepository {
  Future<List<Post>> fetchFeed({int page = 0, int pageSize = 20});

  Future<List<Post>> fetchUserPosts(String userId, {int page = 0, int pageSize = 30});

  Future<Post> createPost({
    required File image,
    required String? caption,
    required String userId,
  });
}
