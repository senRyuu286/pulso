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

  Future<void> deletePost(String postId);

  Future<void> repost({
    required String postId,
    required String userId,
    required bool currentlyReposted,
  });

  Future<Post> fetchPostById(String postId);

  Future<List<Post>> fetchRepostsByUser(String userId);
}
