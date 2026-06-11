class OpenAlexException implements Exception {
  final String message;
  final int? statusCode;
  OpenAlexException(this.message, {this.statusCode});

  @override
  String toString() => 'OpenAlexException: $message (HTTP $statusCode)';
}

class NetworkException extends OpenAlexException {
  NetworkException(super.message);
}

class RateLimitException extends OpenAlexException {
  RateLimitException() : super('Rate limit exceeded. Please wait and retry.', statusCode: 429);
}
