sealed class FeedException implements Exception {
  const FeedException();

  String get message;
}

final class NetworkFeedException extends FeedException {
  const NetworkFeedException();

  @override
  String get message => 'No internet connection. Check your network and try again.';
}

final class UploadFeedException extends FeedException {
  const UploadFeedException(this.detail);

  final String detail;

  @override
  String get message => detail.isEmpty ? 'Failed to upload image.' : detail;
}

final class UnknownFeedException extends FeedException {
  const UnknownFeedException(this.detail);

  final String detail;

  @override
  String get message =>
      detail.isEmpty ? 'Something went wrong. Please try again.' : detail;
}
