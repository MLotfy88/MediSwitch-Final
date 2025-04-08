/// Base class for custom exceptions
class AppException implements Exception {
  final String? message;

  AppException({this.message});

  @override
  String toString() {
    return message ?? runtimeType.toString();
  }
}

/// Exception for server-related errors (e.g., 4xx, 5xx responses, parsing errors)
class ServerException extends AppException {
  ServerException({super.message = 'Server error occurred.'});
}

/// Exception for network connectivity issues (e.g., SocketException, TimeoutException)
class NetworkException extends AppException {
  NetworkException({super.message = 'Network error occurred.'});
}

/// Exception for local cache errors (e.g., SharedPreferences errors)
class CacheException extends AppException {
  CacheException({super.message = 'Cache error occurred.'});
}

/// Exception specifically for initial data load failures
class InitialLoadException extends AppException {
  InitialLoadException({super.message = 'Failed to load initial data.'});
}

// Add other specific exception types as needed
