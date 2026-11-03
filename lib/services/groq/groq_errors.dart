/// Everything that can go wrong talking to Groq, with a message that is safe
/// to show in the chat (no technical words, never the key).
sealed class GroqException implements Exception {
  const GroqException();

  /// Shown to the user.
  String get userMessage;

  /// True when pressing Retry might help.
  bool get canRetry => false;

  /// True when the fix is in Profile (missing or bad key, bad model name).
  bool get needsProfile => false;

  @override
  String toString() => '$runtimeType: $userMessage';
}

class GroqNoKey extends GroqException {
  const GroqNoKey();
  @override
  String get userMessage => 'Add your Groq key to start.';
  @override
  bool get needsProfile => true;
}

class GroqUnauthorized extends GroqException {
  const GroqUnauthorized();
  @override
  String get userMessage => 'Groq rejected the key.';
  @override
  bool get needsProfile => true;
}

class GroqRateLimited extends GroqException {
  const GroqRateLimited({this.retryAfterSeconds});
  final int? retryAfterSeconds;
  @override
  String get userMessage => retryAfterSeconds == null
      ? 'Busy right now. Try again in a moment.'
      : 'Busy right now. Try again in ${retryAfterSeconds}s.';
  @override
  bool get canRetry => true;
}

class GroqNetworkError extends GroqException {
  const GroqNetworkError();
  @override
  String get userMessage => "Couldn't reach Groq.";
  @override
  bool get canRetry => true;
}

class GroqServerError extends GroqException {
  const GroqServerError(this.statusCode);
  final int statusCode;
  @override
  String get userMessage => "Groq had a problem. Try again.";
  @override
  bool get canRetry => true;
}

class GroqModelNotFound extends GroqException {
  const GroqModelNotFound(this.model);
  final String model;
  @override
  String get userMessage => 'Model "$model" is not available. Change it in Profile.';
  @override
  bool get needsProfile => true;
}

class GroqBadRequest extends GroqException {
  const GroqBadRequest(this.detail);
  final String detail;
  @override
  String get userMessage => "Couldn't understand that, try rephrasing.";
}

/// The model answered, but not in a usable shape.
class GroqBadResponse extends GroqException {
  const GroqBadResponse(this.detail);
  final String detail;
  @override
  String get userMessage => "Couldn't understand that, try rephrasing.";
  @override
  bool get canRetry => true;
}
