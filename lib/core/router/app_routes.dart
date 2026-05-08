abstract final class AppRoutes {
	static const String login = '/login';
	static const String register = '/register';
	static const String feed = '/feed';

	static bool isAuthRoute(String location) {
		return location == login || location == register;
	}
}
