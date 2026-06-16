class StorageException implements Exception {
  final String message;
  const StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}

class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  const NetworkException(this.message, {this.statusCode});

  @override
  String toString() => 'NetworkException($statusCode): $message';
}
