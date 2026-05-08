abstract final class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String feed = '/feed';
  static const String createPost = '/create-post';
  static const String profile = '/profile/:userId';

  static String profileFor(String userId) => '/profile/$userId';

  static bool isAuthRoute(String location) {
    return location == login || location == register;
  }
}
