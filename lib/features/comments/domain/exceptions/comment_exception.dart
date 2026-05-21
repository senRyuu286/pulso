/// Base exception for comment-related errors.
sealed class CommentException implements Exception {
  const CommentException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Exception thrown when a comment fetch fails.
final class CommentFetchException extends CommentException {
  const CommentFetchException(super.message);
}

/// Exception thrown when a comment creation fails.
final class CommentCreationException extends CommentException {
  const CommentCreationException(super.message);
}

/// Exception thrown when a comment deletion fails.
final class CommentDeletionException extends CommentException {
  const CommentDeletionException(super.message);
}

/// Exception thrown when a comment like toggle fails.
final class CommentLikeException extends CommentException {
  const CommentLikeException(super.message);
}

/// Exception thrown for unknown comment errors.
final class UnknownCommentException extends CommentException {
  const UnknownCommentException(String message) : super('Unknown error: $message');
}
