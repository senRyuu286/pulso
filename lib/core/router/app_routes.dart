abstract final class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String feed = '/feed';
  static const String search = '/search';
  static const String createPost = '/create-post';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String userProfile = '/user/:userId';

  static String profileFor(String userId) => '/user/$userId';

  static bool isAuthRoute(String location) {
    return location == login || location == register;
  }
}
