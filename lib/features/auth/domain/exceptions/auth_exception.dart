sealed class AuthException implements Exception {
  const AuthException();

  String get message;
}

final class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException();

  @override
  String get message => 'Incorrect email or password. Please try again.';
}

final class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException();

  @override
  String get message => 'This email is already registered.';
}

final class NetworkException extends AuthException {
  const NetworkException();

  @override
  String get message =>
      'No internet connection. Check your network and try again.';
}

final class UnknownAuthException extends AuthException {
  const UnknownAuthException(this.detailMessage);

  final String detailMessage;

  @override
  String get message => detailMessage.isEmpty
      ? 'Something went wrong. Please try again.'
      : detailMessage;
}
