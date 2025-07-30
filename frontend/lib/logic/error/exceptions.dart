// Implementing basic exception categories

// An exception for situations where issues lies with the server

class ServerException implements Exception {
  final String message;

  ServerException(this.message);
}

// An exception to handle cache problems
class CacheException implements Exception {
  final String message;

  CacheException(this.message);
}

// An exception to handle invalid users
class InvalidUserException implements Exception {
  final String message;

  InvalidUserException(this.message);
}
