abstract class AppException implements Exception {
  final String message;
  final String? code;
  
  const AppException(this.message, [this.code]);
  
  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, [super.code]);
}

class NetworkException extends AppException {
  const NetworkException(super.message, [super.code]);
}

class FileSystemException extends AppException {
  const FileSystemException(super.message, [super.code]);
}

class PermissionException extends AppException {
  const PermissionException(super.message, [super.code]);
}

class EncryptionException extends AppException {
  const EncryptionException(super.message, [super.code]);
}

class AIServiceException extends AppException {
  const AIServiceException(super.message, [super.code]);
}

class SyncException extends AppException {
  const SyncException(super.message, [super.code]);
}

class AuthenticationException extends AppException {
  const AuthenticationException(super.message, [super.code]);
}